
import
  std/[
    strutils,
    sequtils,
    json,
    critbits,
    algorithm,
    streams,
    terminal,
    os
  ]

import
  env,
  meta,
  interpreter,
  parser,
  stdlib,
  utils,
  value

import
  minline

var SIMPLEREPL* = false

proc interpret*(i: In, s: string): MinValue =
  i.open(newStringStream(s), i.filename)
  discard i.parser.getToken()
  try:
    result = i.interpret()
  except CatchableError:
    discard
    i.close()

proc getCompletions*(ed: LineEditor, i: MinInterpreter): seq[string] =
  let symbols = toSeq(i.scope.symbols.keys)
  var words = ed.lineText.split(" ")
  var word: string
  if words.len == 0:
    word = ed.lineText
  else:
    word = words[words.len-1]
  if word.startsWith("'"):
    return symbols.mapIt("'" & $it)
  if word.startsWith("~"):
    return symbols.mapIt("~" & $it)
  if word.startsWith("?"):
    return symbols.mapIt("?" & $it)
  if word.startsWith("@"):
    return symbols.mapIt("@" & $it)
  if word.startsWith("#"):
    return symbols.mapIt("#" & $it)
  if word.startsWith(">"):
    return symbols.mapIt(">" & $it)
  if word.startsWith("*") and word.contains("/"):
    let dicts = word.substr(1).split("/")
    var op: MinOperator
    var dict: MinValue
    var path = "*"
    for d in dicts:
      if dict.isNil:
        if i.scope.symbols.hasKey(d):
          op = i.scope.symbols[d]
          if op.kind == minProcOp and not op.mdl.isNil:
            dict = op.mdl
          elif op.kind == minValOp and op.val.kind == minDictionary:
            dict = op.val
        path &= d & "/"
      elif dict.dVal.hasKey(d):
        op = dict.dVal[d]
        if op.kind == minProcOp and not op.mdl.isNil:
          dict = op.mdl
        elif op.kind == minValOp and op.val.kind == minDictionary:
          dict = op.val
        path &= d & "/"
    return dict.dVal.keys.toSeq.mapIt(path & it)
  if word.startsWith("*"):
    let filterProc = proc (it: string): bool =
      let op = i.scope.symbols[it]
      if op.kind == minProcOp and not op.mdl.isNil:
        return true
      else:
        return op.kind == minValOp and op.val.kind == minDictionary
    return symbols.filter(filterProc).mapIt("*" & $it)
  if word.startsWith("("):
    return symbols.mapIt("(" & $it)
  if word.startsWith("<"):
    return toSeq(MINSYMBOLS.readFile.parseJson.pairs).mapIt("<" & $it[0])
  if word.startsWith("$"):
    return toSeq(envPairs()).mapIt("$" & $it[0])
  if word.startsWith("\""):
    var f = word[1..^1]
    if f == "":
      f = getCurrentDir().replace("\\", "/")
      return toSeq(walkDir(f, true)).mapIt("\"$1" % it.path.replace("\\", "/"))
    elif f.dirExists:
      f = f.replace("\\", "/")
      if f[f.len-1] != '/':
        f = f & "/"
      return toSeq(walkDir(f, true)).mapIt("\"$1$2" % [f, it.path.replace("\\", "/")])
    else:
      var dir: string
      if f.contains("/") or dir.contains("\\"):
        dir = f.parentDir
        let file = f.extractFileName
        return toSeq(walkDir(dir, true)).filterIt(
            it.path.toLowerAscii.startsWith(file.toLowerAscii)).mapIt(
            "\"$1/$2" % [dir, it.path.replace("\\", "/")])
      else:
        dir = getCurrentDir()
        return toSeq(walkDir(dir, true)).filterIt(
            it.path.toLowerAscii.startsWith(f.toLowerAscii)).mapIt("\"$1" % [
            it.path.replace("\\", "/")])
  return symbols

proc p(s: string, color = fgWhite) =
  if SIMPLEREPL:
    stdout.write(s)
  else:
    stdout.styledWrite(color, s)

proc pv(item: MinValue) =
  case item.kind
  of minNull, minBool:
    p($item, fgGreen)
  of minSymbol:
    p($item, fgCyan)
  of minString:
    p($item, fgYellow)
  of minFloat, minInt:
    p($item, fgMagenta)
  of minQuotation:
    p("( ", fgRed)
    for val in item.qVal:
      pv(val); stdout.write(" ")
    p(")", fgRed)
  of minCommand:
    p("[ ", fgRed)
    p(item.cmdVal, fgRed)
    p(" ]", fgRed)
  of minDictionary:
    p("{ ", fgRed)
    for val in item.dVal.pairs:
      var v: MinValue
      if val.val.kind == minProcOp:
        v = "<native>".newSym
      else:
        v = val.val.val
      pv(v); p(" :" & $val.key & " ", fgCyan)
    p("}", fgRed)

proc printResult(i: In, res: MinValue) =
  if res.isNil:
    return
  if i.stack.len > 0:
    let n = $i.stack.len
    if res.isQuotation and res.qVal.len > 1:
      p(" (\n", fgRed)
      for item in res.qVal:
        p("   "); pv(item); stdout.write("\n")
      stdout.write(" ".repeat(n.len)); p(")\n", fgRed)
    elif res.isCommand:
      p(" [", fgRed); p(res.cmdVal, fgYellow); p("]\n")
    elif res.isDictionary and res.dVal.len > 1:
      p(" {\n", fgRed)
      for item in res.dVal.pairs:
        var v: MinValue
        if item.val.kind == minProcOp:
          v = "<native>".newSym
        else:
          v = item.val.val
        p("   "); pv(v); p(" :" & $item.key & "\n", fgCyan)
      if res.objType == "":
        stdout.write " ".repeat(n.len); p("}\n", fgRed)
      else:
        stdout.write " ".repeat(n.len); p("  ;" & res.objType & "\n", fgBlue)
        stdout.write " ".repeat(n.len); p("}\n", fgRed)
    else:
      stdout.write " "; pv(i.stack[i.stack.len - 1]); stdout.write("\n")

proc minSimpleRepl*(i: var MinInterpreter) =
  i.stdLib()
  var s = newStringStream("")
  i.open(s, "<repl>")
  var line: string
  while true:
    i.push(i.newSym("prompt"))
    let vals = i.expect("str")
    let v = vals[0]
    let prompt = v.getString()
    stdout.write(prompt)
    stdout.flushFile()
    line = stdin.readLine()
    let r = i.interpret($line)
    if $line != "":
      i.printResult(r)

proc minRepl*(i: var MinInterpreter) =
  DEV = true
  i.stdLib()
  var s = newStringStream("")
  i.open(s, "<repl>")
  var line: string
  echo "$# shell v$#" % [pkgName, pkgVersion]
  while true:
    let iref = i
    EDITOR.completionCallback = proc(ed: LineEditor): seq[string] =
      var completions = ed.getCompletions(iref)
      completions.sort()
      return completions
    # evaluate prompt
    i.push(i.newSym("prompt"))
    let vals = i.expect("str")
    let v = vals[0]
    let prompt = v.getString()
    line = EDITOR.readLine(prompt)
    let r = i.interpret($line)
    if $line != "":
      i.printResult(r)

proc minRepl*() =
  var i = newMinInterpreter(filename = "<repl>")
  i.minRepl()

proc minSimpleRepl*() =
  var i = newMinInterpreter(filename = "<repl>")
  i.minSimpleRepl()
