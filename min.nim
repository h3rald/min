import
  std/[streams,
  strutils,
  sequtils,
  times,
  json,
  os,
  algorithm,
  logging],
  minline
import
  minpkg/core/[niftylogger,
  baseutils,
  env,
  parser,
  value,
  scope,
  interpreter,
  utils]
import
  minpkg/lib/[min_lang,
  min_stack,
  min_seq,
  min_dict,
  min_num,
  min_str,
  min_logic,
  min_time,
  min_sys,
  min_io,
  min_dstore,
  min_fs,
  min_xml,
  min_http,
  min_net,
  min_crypto,
  min_math]

export
  env,
  parser,
  interpreter,
  utils,
  value,
  scope,
  min_lang,
  niftylogger

const PRELUDE* = "prelude.min".slurp.strip
var NIMOPTIONS* = ""
var MINMODULES* = newSeq[string](0)
var customPrelude {.threadvar.}: string
customPrelude = ""

if logging.getHandlers().len == 0:
  newNiftyLogger().addHandler()

proc getExecs(): seq[string] =
  var res = newSeq[string](0)
  let getFiles = proc(dir: string) =
    for c, s in walkDir(dir, true):
      if (c == pcFile or c == pcLinkToFile) and not res.contains(s):
        res.add s
  getFiles(getCurrentDir())
  for dir in "PATH".getEnv.split(PathSep):
    getFiles(dir)
  res.sort(system.cmp)
  return res

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
  if word.startsWith("!"):
    return getExecs().mapIt("!" & $it)
  if word.startsWith("!!"):
    return getExecs().mapIt("!!" & $it)
  if word.startsWith("!\""):
    return getExecs().mapIt("!\"" & $it)
  if word.startsWith("!!\""):
    return getExecs().mapIt("!!\"" & $it)
  if word.startsWith("&\""):
    return getExecs().mapIt("&\"" & $it)
  if word.startsWith("&"):
    return getExecs().mapIt("&" & $it)
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


proc stdLib*(i: In) =
  setLogFilter(logging.lvlNotice)
  if not MINSYMBOLS.fileExists:
    MINSYMBOLS.writeFile("{}")
  if not MINHISTORY.fileExists:
    MINHISTORY.writeFile("")
  if not MINRC.fileExists:
    MINRC.writeFile("")
  i.lang_module
  i.stack_module
  i.seq_module
  i.dict_module
  i.logic_module
  i.num_module
  i.str_module
  i.time_module
  i.sys_module
  i.fs_module
  i.dstore_module
  i.io_module
  i.crypto_module
  i.net_module
  i.math_module
  i.http_module
  i.xml_module
  if customPrelude == "":
    i.eval PRELUDE, "<prelude>"
  else:
    try:
      i.eval customPrelude.readFile, customPrelude
    except CatchableError:
      logging.warn("Unable to process custom prelude code in $1" % customPrelude)
  try:
    i.eval MINRC.readFile()
  except CatchableError:
    error "An error occurred evaluating the .minrc file."

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  i.open(s, i.filename)
  discard i.parser.getToken()
  try:
    i.interpret()
  except CatchableError:
    discard
  i.close()

proc interpret*(i: In, s: string): MinValue =
  i.open(newStringStream(s), i.filename)
  discard i.parser.getToken()
  try:
    result = i.interpret()
  except CatchableError:
    discard
    i.close()

proc minFile*(fn: string, op = "interpret", main = true): seq[
    string] {.discardable.}

proc compile*(i: In, s: Stream, main = true): seq[string] =
  if "nim".findExe == "":
    logging.error "Nim compiler not found, unable to compile."
    quit(7)
  result = newSeq[string](0)
  i.open(s, i.filename)
  discard i.parser.getToken()
  try:
    MINCOMPILED = true
    let dotindex = i.filename.rfind(".")
    let nimFile = i.filename[0..dotindex-1] & ".nim"
    if main:
      logging.notice("Generating $#..." % nimFile)
      result = i.initCompiledFile(MINMODULES)
      for m in MINMODULES:
        let f = m.replace("\\", "/")
        result.add "### $#" % f
        logging.notice("- Including: $#" % f)
        result = result.concat(minFile(f, "compile", main = false))
      result.add "### $# (main)" % i.filename
      result = result.concat(i.compileFile(main))
      writeFile(nimFile, result.join("\n"))
      let cmd = "nim c $#$#" % [NIMOPTIONS&" ", nimFile]
      logging.notice("Calling Nim compiler:")
      logging.notice(cmd)
      discard execShellCmd(cmd)
    else:
      result = result.concat(i.compileFile(main))
  except CatchableError:
    discard
  i.close()

proc minStream(s: Stream, filename: string, op = "interpret", main = true): seq[
    string] {.discardable.} =
  var i = newMinInterpreter(filename = filename)
  i.pwd = filename.parentDirEx
  if op == "interpret":
    i.interpret(s)
    newSeq[string](0)
  else:
    i.compile(s, main)

proc minStr*(buffer: string) =
  minStream(newStringStream(buffer), "input")

proc minFile*(fn: string, op = "interpret", main = true): seq[
    string] {.discardable.} =
  var fileLines = newSeq[string](0)
  var contents = ""
  try:
    fileLines = fn.readFile().splitLines()
  except CatchableError:
    logging.fatal("Cannot read from file: " & fn)
    quit(3)
  if fileLines[0].len >= 2 and fileLines[0][0..1] == "#!":
    contents = ";;\n" & fileLines[1..fileLines.len-1].join("\n")
  else:
    contents = fileLines.join("\n")
  minStream(newStringStream(contents), fn, op, main)

when isMainModule:
  import
    terminal,
    parseopt,
    critbits,
    minpkg/core/meta

  var REPL = false
  var SIMPLEREPL = false
  var MODULEPATH = ""
  var exeName = "min"

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
    echo "$# shell v$#" % [exeName, pkgVersion]
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

  proc resolveFile(file: string): string =
    if (file.endsWith(".min") or file.endsWith(".mn")) and fileExists(file):
      return file
    elif fileExists(file&".min"):
      return file&".min"
    elif fileExists(file&".mn"):
      return file&".mn"
    return ""

  let usage* = """  $exe v$version - a small but practical concatenative programming language
  (c) 2014-$year Fabio Cevasco
  
  Usage:
    $exe [options] [filename | command] [...comamand-arguments]

  Arguments:
    filename  A $exe file to interpret or compile 
    command   A command to execute
  Commands:
    compile <file>.min   Compile <file>.min.
    eval <string>        Evaluate <string> as a min program.
    help <symbol>        Print the help contents related to <symbol>.
  Options:
    -a, --asset-path          Specify a directory containing the asset files to include in the
                              compiled executable (if -c is set)
    -d, --dev                 Enable "development mode" (runtime checks)
    -h, --help                Print this help
    -i, --interactive         Start $exe shell (with advanced prompt, default if no file specidied)"
    -j, --interactive-simple  Start $exe shell (without advanced prompt)
    -l, --log                 Set log level (debug|info|notice|warn|error|fatal)
                              Default: notice
    -m, --module-path         Specify a directory containing the .min files to include in the
                              compiled executable (if -c is set)
    -n, --passN               Pass options to the nim compiler (if -c is set)
    -p, --prelude:<file.min>  If specified, it loads <file.min> instead of the default prelude code
    -v, —-version             Print the program version""" % [
      "exe", exeName,
      "version", pkgVersion,
      "year", $(now().year)
  ]

  var file = ""
  var args = newSeq[string](0)
  logging.setLogFilter(logging.lvlNotice)
  var p = initOptParser()

  for kind, key, val in getopt(p):
    case kind:
      of cmdArgument:
        args.add key
        if file == "":
          file = key
      of cmdLongOption, cmdShortOption:
        case key:
          of "module-path", "m":
            MODULEPATH = val
          of "asset-path", "a":
            ASSETPATH = val
          of "prelude", "p":
            customPrelude = val
          of "dev", "d":
            DEV = true
          of "log", "l":
            if file == "":
              var val = val
              niftylogger.setLogLevel(val)
          of "passN", "n":
            NIMOPTIONS = val
          of "help", "h":
            if file == "":
              echo usage
              quit(0)
          of "version", "v":
            if file == "":
              echo pkgVersion
              quit(0)
          of "interactive", "i":
            if file == "":
              REPL = true
          of "interactive-simple", "j":
            if file == "":
              SIMPLEREPL = true
          else:
            discard
      else:
        discard
  var op = "interpret"
  if MODULEPATH.len > 0:
    for f in walkDirRec(MODULEPATH):
      if f.endsWith(".min"):
        MINMODULES.add f
  elif REPL:
    minRepl()
    quit(0)
  if file != "":
    var fn = resolveFile(file)
    if fn == "":
      if file == "compile":
        op = "compile"
        if args.len < 2:
          logging.error "[compile] No file was specified."
          quit(8)
        fn = resolveFile(args[1])
        if fn == "":
          logging.error "[compile] File '$#' does not exist." % [args[1]]
          quit(9)
      elif file == "eval":
        if args.len < 2:
          logging.error "[eval] No string to evaluate was specified."
          quit(9)
        minStr args[1]
        quit(0)
      elif file == "help":
        if args.len < 2:
          logging.error "[help] No symbol to lookup was specified."
          quit(9)
        minStr("\"$#\" help" % [args[1]])
        quit(0)
    minFile fn, op
  elif SIMPLEREPL:
    minSimpleRepl()
    quit(0)
  else:
    if isatty(stdin):
      minRepl()
      quit(0)
    else:
      minStream newFileStream(stdin), "stdin", op
