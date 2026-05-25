
import
  std/[
    strutils,
    sequtils,
    critbits,
    algorithm,
    streams,
    terminal,
    json,
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
  finally: 
    i.close()

proc getCompletions*(ed: LineEditor, i: MinInterpreter): seq[string] =
  let symbols = toSeq(i.scope.symbols.keys)
  var words = ed.lineText.split(" ")
  var word: string
  if words.len == 0:
    word = ed.lineText
  else:
    word = words[words.len-1]
  if word.contains("."):
    var op: MinOperator
    var dict: MinValue = MinValue(kind: minUnknown)
    var path = ""
    if ['?', '@', '\'', '~', '#'].contains(word[0]):
      path &= word[0]
      word = word[1..^1]
    let dicts = word.split(".")
    for d in dicts:
      if dict.isUnknown: # Not initialized yet
        if i.scope.symbols.hasKey(d):
          op = i.scope.symbols[d]
          if op.kind == minProcOp and not op.mdl.isUnknown:
            dict = op.mdl
          elif op.kind == minValOp and op.val.kind == minDictionary:
            dict = op.val
        path &= d & "."
      elif dict.dVal.hasKey(d):
        op = dict.dVal[d]
        if op.kind == minProcOp and not op.mdl.isUnknown:
          dict = op.mdl
        elif op.kind == minValOp and op.val.kind == minDictionary:
          dict = op.val
        path &= d & "."
    return dict.dVal.keys.toSeq.mapIt(path & it)
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
  if word.startsWith("$"):
    return toSeq(envPairs()).mapIt("$" & $it[0])
  if word.startsWith("\""):
    var f = word[1..^1]
    if f == "":
      f = getCurrentDir().replace("\\", "/")
      return toSeq(walkDir(f, true)).mapIt("\"$1" % it.path.replace("\\", "/")&"\"")
    elif f.dirExists:
      f = f.replace("\\", "/")
      if f[f.len-1] != '/':
        f = f & "/"
      return toSeq(walkDir(f, true)).mapIt("\"$1$2\"" % [f, it.path.replace(
          "\\", "/")])
    else:
      var dir: string
      if f.contains("/") or dir.contains("\\"):
        dir = f.parentDir
        let file = f.extractFileName
        return toSeq(walkDir(dir, true)).filterIt(
            it.path.toLowerAscii.startsWith(file.toLowerAscii)).mapIt(
            "\"$1/$2\"" % [dir, it.path.replace("\\", "/")])
      else:
        dir = getCurrentDir()
        return toSeq(walkDir(dir, true)).filterIt(
            it.path.toLowerAscii.startsWith(f.toLowerAscii)).mapIt("\"$1\"" % [
            it.path.replace("\\", "/")])
  return symbols

proc p(s: string, color = fgWhite) =
  if SIMPLEREPL or not COLOR:
    stdout.write(s)
  else:
    stdout.styledWrite(color, s)

proc printSymbol(i: In, s: string) =
  let pS = i.processSymbolValue(s)
  if pS.len == 0:
    p(s, fgCyan)
  else:
    for part in pS.items:
      if part["type"].getStr == "tkDict":
        p(part["value"].getStr, fgBlue)
      elif part["type"].getStr == "tkGlobalSymbol":
        p(part["value"].getStr, fgMagenta)
      elif ["tkDot", "tkAutopop", "tkSystemSigil"].contains part[
          "type"].getStr:
        p(part["value"].getStr, fgRed)
      else:
        p(part["value"].getStr, fgCyan)

proc pv(i:In, item: MinValue) =
  case item.kind
  of minNull, minBool, minFloat, minInt, minUnknown:
    p($item, fgGreen)
  of minSymbol:
    i.printSymbol($item)
  of minString:
    p($item, fgYellow)
  of minQuotation:
    p("( ", fgRed)
    for val in item.qVal:
      i.pv(val); stdout.write(" ")
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
      var keyType = " :"
      if val.val.lambda:
        keyType = " ^"
      i.pv(v); p(keyType & $val.key & " ", fgCyan)
    p("}", fgRed)

proc printResult(i: In, res: MinValue) =
  if res.isUnknown:
    return
  if i.stack.len > 0:
    let n = $i.stack.len
    if res.isQuotation and res.qVal.len > 1:
      p(" (\n", fgRed)
      for item in res.qVal:
        p("   "); i.pv(item); stdout.write("\n")
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
        var keyType = " :"
        if item.val.lambda:
          keyType = " ^"
        p("   "); i.pv(v); p(keyType & $item.key & "\n", fgCyan)
      if res.objType == "":
        stdout.write " ".repeat(n.len); p("}\n", fgRed)
      else:
        stdout.write " ".repeat(n.len); p("  ;" & res.objType & "\n", fgBlue)
        stdout.write " ".repeat(n.len); p("}\n", fgRed)
    else:
      stdout.write " "; i.pv(i.stack[i.stack.len - 1]); stdout.write("\n")

proc minSimpleRepl*(i: var MinInterpreter) =
  i.stdLib()
  var s = newStringStream("")
  i.open(s, "<repl>")
  var line: string
  while true:
    ERRORS_HANDLED = true # Avoid printing error hint on CTRL+C
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
    ERRORS_HANDLED = true # Avoid printing error hint on CTRL+C
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
