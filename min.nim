import 
  streams, 
  strutils, 
  sequtils

when defined(mini):
  import
    minpkg/core/minilogger
else:
  import 
    json,
    os,
    algorithm,
    logging,
    minpkg/packages/niftylogger
import 
  minpkg/core/baseutils,
  minpkg/core/env,
  minpkg/core/parser, 
  minpkg/core/value, 
  minpkg/core/scope,
  minpkg/core/interpreter, 
  minpkg/core/utils
import 
  minpkg/lib/min_lang, 
  minpkg/lib/min_stack, 
  minpkg/lib/min_seq, 
  minpkg/lib/min_dict, 
  minpkg/lib/min_num,
  minpkg/lib/min_str,
  minpkg/lib/min_logic,
  minpkg/lib/min_time

when not defined(mini):
  import
    minpkg/packages/nimline/nimline,
    minpkg/lib/min_sys,
    minpkg/lib/min_io,
    minpkg/lib/min_dstore,
    minpkg/lib/min_fs

when not defined(lite) and not defined(mini):
  import 
    minpkg/lib/min_http,
    minpkg/lib/min_net,
    minpkg/lib/min_crypto,
    minpkg/lib/min_math

export 
  env,
  parser,
  interpreter,
  utils,
  value,
  scope,
  min_lang

when defined(mini):
  export minilogger
else:
  export niftylogger

const PRELUDE* = "prelude.min".slurp.strip
var NIMOPTIONS* = ""
var MINMODULES* = newSeq[string](0)
var customPrelude {.threadvar.} : string
customPrelude = ""

when not defined(mini):
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
          return toSeq(walkDir(dir, true)).filterIt(it.path.toLowerAscii.startsWith(file.toLowerAscii)).mapIt("\"$1/$2" % [dir, it.path.replace("\\", "/")])
        else:
          dir = getCurrentDir()
          return toSeq(walkDir(dir, true)).filterIt(it.path.toLowerAscii.startsWith(f.toLowerAscii)).mapIt("\"$1" % [it.path.replace("\\", "/")])
    return symbols


proc stdLib*(i: In) =
  when not defined(mini):
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
  when not defined(mini):
    i.sys_module
    i.fs_module
    i.dstore_module
    i.io_module
  when not defined(lite) and not defined(mini):
    i.crypto_module
    i.net_module
    i.math_module
    i.http_module
  if customPrelude == "":
    i.eval PRELUDE, "<prelude>"
  else:
    try:
      i.eval customPrelude.readFile, customPrelude
    except:
      when defined(mini):
        minilogger.warn("Unable to process custom prelude code in $1" % customPrelude)
      else:
        logging.warn("Unable to process custom prelude code in $1" % customPrelude)
  when not defined(mini):
    try:
      i.eval MINRC.readFile()
    except:
      error "An error occurred evaluating the .minrc file."

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  i.open(s, i.filename)
  discard i.parser.getToken() 
  try:
    i.interpret()
  except:
    discard
  i.close()

proc interpret*(i: In, s: string): MinValue = 
  i.open(newStringStream(s), i.filename)
  discard i.parser.getToken() 
  try:
    result = i.interpret()
  except:
    discard
    i.close()
    
proc minFile*(filename: string, op = "interpret", main = true): seq[string] {.discardable.}

proc compile*(i: In, s: Stream, main = true): seq[string] = 
  when not defined(mini):
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
      when defined(mini):
        minilogger.notice("Generating $#..." % nimFile)
      else:
        logging.notice("Generating $#..." % nimFile)
      result = i.initCompiledFile(MINMODULES)
      for m in MINMODULES:
        let f = m.replace("\\", "/")
        result.add "### $#" % f
        when defined(mini):
          minilogger.notice("- Including: $#" % f)
        else:
          logging.notice("- Including: $#" % f)
        result = result.concat(minFile(f, "compile", main = false))
      result.add "### $# (main)" % i.filename
      result = result.concat(i.compileFile(main))
      writeFile(nimFile, result.join("\n"))
      when not defined(mini):
        let cmd = "nim c $#$#" % [NIMOPTIONS&" ", nimFile]
        logging.notice("Calling Nim compiler:")
        logging.notice(cmd)
        discard execShellCmd(cmd)
      else:
        minilogger.notice("$# generated successfully, call the nim compiler to compile it.")
    else:
      result = result.concat(i.compileFile(main))
  except:
    discard
  i.close()

proc minStream(s: Stream, filename: string, op = "interpret", main = true): seq[string] {.discardable.}= 
  var i = newMinInterpreter(filename = filename)
  i.pwd = filename.parentDirEx
  if op == "interpret":
    i.interpret(s)
    newSeq[string](0)
  else:
    i.compile(s, main)

proc minStr*(buffer: string) =
  minStream(newStringStream(buffer), "input")

proc minFile*(filename: string, op = "interpret", main = true): seq[string] {.discardable.} =
  var fn = filename
  if not filename.endsWith(".min"):
    fn &= ".min"
  var fileLines = newSeq[string](0)
  var contents = ""
  try:
    fileLines = fn.readFile().splitLines()
  except:
    when defined(mini):
      minilogger.fatal("Cannot read from file: " & fn)
    else:
      logging.fatal("Cannot read from file: " & fn)
    quit(3)
  if fileLines[0].len >= 2 and fileLines[0][0..1] == "#!":
    contents = ";;\n" & fileLines[1..fileLines.len-1].join("\n")
  else:
    contents = fileLines.join("\n")
  minStream(newStringStream(contents), fn, op, main)

when isMainModule:
  when not defined(mini):
    import terminal
  import 
    parseopt,
    critbits,
    minpkg/core/meta

  var REPL = false
  var SIMPLEREPL = false
  var COMPILE = false
  var MODULEPATH = ""
  var exeName = "min"
  var iOpt = "\n    -i, --interactive         Start $1 shell (with advanced prompt, default if no file specidied)\n"
  when defined(lite):
    exeName = "litemin"
  when defined(mini):
    iOpt = ""
    exeName = "minimin"

  proc printResult(i: In, res: MinValue) =
    if res.isNil:
      return
    if i.stack.len > 0:
      let n = $i.stack.len
      if res.isQuotation and res.qVal.len > 1:
        echo " ("
        for item in res.qVal:
          echo  "   " & $item
        echo " ".repeat(n.len) & ")"
      elif res.isDictionary and res.dVal.len > 1:
        echo " {"
        for item in res.dVal.pairs:
          var v = ""
          if item.val.kind == minProcOp:
            v = "<native>"
          else:
            v = $item.val.val
          echo  "   " & v & " :" & $item.key
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

  when not defined(mini):

    proc minRepl*(i: var MinInterpreter) =
      i.stdLib()
      var s = newStringStream("")
      i.open(s, "<repl>")
      var line: string
      echo "$# shell v$#" % [exeName, pkgVersion]
      while true:
        let symbols = toSeq(i.scope.symbols.keys)
        EDITOR.completionCallback = proc(ed: LineEditor): seq[string] =
          return ed.getCompletions(symbols)
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
      

  let usage* = """  $exe v$version - a tiny concatenative programming language
  (c) 2014-2021 Fabio Cevasco
  
  Usage:
    $exe [options] [filename]

  Arguments:
    filename  A $exe file to interpret or compile 
  Options:
    -a, --asset-path          Specify a directory containing the asset files to include in the
                              compiled executable (if -c is set)
    -c, --compile             Compile the specified file
    -e, --evaluate            Evaluate a $exe program inline
    -h, --help                Print this help$iOpt
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
      "iOpt", iOpt
  ]

  var file, s: string = ""
  var args = newSeq[string](0)
  when defined(mini):
    minilogger.setLogFilter(minilogger.lvlNotice)
  else:
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
          of "compile", "c":
            COMPILE = true
          of "module-path", "m":
            MODULEPATH = val
          of "asset-path", "a":
            ASSETPATH = val
          of "prelude", "p":
            customPrelude = val
          of "log", "l":
            if file == "":
              var val = val
              when defined(mini):
                minilogger.setLogLevel(val)
              else:
                niftylogger.setLogLevel(val)
          of "passN", "n":
              NIMOPTIONS = val
          of "evaluate", "e":
            if file == "":
              s = val
          of "help", "h":
            if file == "":
              echo usage
              quit(0)
          of "version", "v":
            if file == "":
              echo pkgVersion
              quit(0)
          of "interactive", "i":
            if file == "" and not defined(mini):
              REPL = true
          of "interactive-simple", "j":
            if file == "":
              SIMPLEREPL = true
          else:
            discard
      else:
        discard
  var op = "interpret"
  if COMPILE:
    op = "compile"

  when not defined(mini):
    if MODULEPATH.len > 0:
      for f in walkDirRec(MODULEPATH):
        if f.endsWith(".min"):
          MINMODULES.add f
    elif REPL:
      minRepl()
      quit(0)
  if s != "":
    minStr(s)
  elif file != "":
    minFile file, op
  elif SIMPLEREPL:
    minSimpleRepl()
    quit(0)
  else:
    when defined(mini):
      minStream newFileStream(stdin), "stdin", op
    else:
      if isatty(stdin):
        minRepl()
        quit(0)
      else:
        minStream newFileStream(stdin), "stdin", op
