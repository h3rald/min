
import
  std/[
    strutils,
    sequtils,
    json,
    critbits,
    algorithm,
    streams,
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

proc interpret*(i: In, s: string): MinValue =
  i.open(newStringStream(s), i.filename)
  discard i.parser.getToken()
  try:
    result = i.interpret()
  except CatchableError:
    discard
    i.close()

proc getCompletions*(ed: LineEditor, symbols: seq[string]): seq[string] =
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
  if word.startsWith("*"):
    return symbols.mapIt("*" & $it)
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

proc printResult(i: In, res: MinValue) =
  if res.isNil:
    return
  if i.stack.len > 0:
    let n = $i.stack.len
    if res.isQuotation and res.qVal.len > 1:
      echo " ("
      for item in res.qVal:
        echo "   " & $item
      echo " ".repeat(n.len) & ")"
    elif res.isCommand:
      echo " [" & res.cmdVal & "]"
    elif res.isDictionary and res.dVal.len > 1:
      echo " {"
      for item in res.dVal.pairs:
        var v = ""
        if item.val.kind == minProcOp:
          v = "<native>"
        else:
          v = $item.val.val
        echo "   " & v & " :" & $item.key
      if res.objType == "":
        echo " ".repeat(n.len) & "}"
      else:
        echo " ".repeat(n.len) & "  ;" & res.objType
        echo " ".repeat(n.len) & "}"
    else:
      echo " $1" % [$i.stack[i.stack.len - 1]]

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
    let symbols = toSeq(i.scope.symbols.keys)
    EDITOR.completionCallback = proc(ed: LineEditor): seq[string] =
      var completions = ed.getCompletions(symbols)
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
