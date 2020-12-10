import 
  streams, 
  critbits, 
  strutils, 
  os, 
  sequtils,
  logging

when not defined(mini):
  import 
    json,
    algorithm,
    dynlib

import 
  packages/niftylogger,
  core/env,
  core/parser, 
  core/value, 
  core/scope,
  core/interpreter, 
  core/utils
import 
  lib/min_lang, 
  lib/min_stack, 
  lib/min_seq, 
  lib/min_dict, 
  lib/min_num,
  lib/min_str,
  lib/min_logic,
  lib/min_time

when not defined(mini):
  import
    packages/nimline/nimline,
    lib/min_io,
    lib/min_sys,
    lib/min_fs

when not defined(lite) and not defined(mini):
  import 
    lib/min_http,
    lib/min_net,
    lib/min_crypto,
    lib/min_math

export 
  env,
  parser,
  interpreter,
  utils,
  niftylogger,
  value,
  scope,
  min_lang


const PRELUDE* = "prelude.min".slurp.strip
var NIMOPTIONS* = ""
var MINMODULES* = newSeq[string](0)
var customPrelude = ""

if logging.getHandlers().len == 0:
  newNiftyLogger().addHandler()

when not defined(mini):
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

when not defined(mini):
  proc getCompletions(ed: LineEditor, symbols: seq[string]): seq[string] =
    var words = ed.lineText.split(" ")
    var word: string
    if words.len == 0:
      word = ed.lineText
    else:
      word = words[words.len-1]
    if word.startsWith("’"):
      return symbols.mapIt("’" & $it)
    elif word.startsWith("~"):
      return symbols.mapIt("~" & $it)
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
  setLogFilter(lvlNotice)
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
      warn("Unable to process custom prelude code in $1" % customPrelude)
  i.eval MINRC.readFile()

when not defined(mini):
  type
    LibProc = proc(i: In) {.nimcall.}

  proc dynLib*(i: In) =
    discard MINLIBS.existsOrCreateDir
    for library in walkFiles(MINLIBS & "/*"):
      var modname = library.splitFile.name
      var libfile = library.splitFile.name & library.splitFile.ext
      if modname.len > 3 and modname[0..2] == "lib":
        modname = modname[3..modname.len-1]
      let dll = library.loadLib()
      if dll != nil:
        let modsym = dll.symAddr(modname)
        if modsym != nil:
          let modproc = cast[LibProc](dll.symAddr(modname))
          i.modproc()
          info("[$1] Dynamic module loaded successfully: $2" % [libfile, modname])
        else:
          warn("[$1] Library does not contain symbol $2" % [libfile, modname])
      else:
        warn("Unable to load dynamic library: " & libfile)

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  when not defined(mini):
    i.dynLib()
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
  if "nim".findExe == "":
    error "Nim compiler not found, unable to compile."
    quit(7)
  result = newSeq[string](0)
  i.open(s, i.filename)
  discard i.parser.getToken() 
  try:
    MINCOMPILED = true
    let nimFile = i.filename.changeFileExt("nim")
    if main:
      notice("Generating $#..." % nimFile)
      result = i.initCompiledFile(MINMODULES)
      for m in MINMODULES:
        let f = m.replace("\\", "/")
        result.add "### $#" % f
        notice("- Including: $#" % f)
        result = result.concat(minFile(f, "compile", main = false))
      result.add "### $# (main)" % i.filename
      result = result.concat(i.compileFile(main))
      writeFile(nimFile, result.join("\n"))
      let cmd = "nim c $#$#" % [NIMOPTIONS&" ", nimFile]
      notice("Calling Nim compiler:")
      notice(cmd)
      discard execShellCmd(cmd)
    else:
      result = result.concat(i.compileFile(main))
  except:
    discard
  i.close()

proc minStream(s: Stream, filename: string, op = "interpret", main = true): seq[string] {.discardable.}= 
  var i = newMinInterpreter(filename = filename)
  i.pwd = filename.parentDir
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
    fatal("Cannot read from file: " & fn)
    quit(3)
  if fileLines[0].len >= 2 and fileLines[0][0..1] == "#!":
    contents = ";;\n" & fileLines[1..fileLines.len-1].join("\n")
  else:
    contents = fileLines.join("\n")
  minStream(newStringStream(contents), fn, op, main)

proc minFile*(file: File, filename="stdin", op = "interpret") =
  var stream = newFileStream(filename)
  if stream == nil:
    fatal("Cannot read from file: " & filename)
    quit(3)
  minStream(stream, filename, op)

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
  when not defined(mini):
    i.dynLib()
  var s = newStringStream("")
  i.open(s, "<repl>")
  var line: string
  while true:
    i.push("prompt".newSym)
    let vals = i.expect("string")
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
    i.dynLib()
    var s = newStringStream("")
    i.open(s, "<repl>")
    var line: string
    var ed = initEditor(historyFile = MINHISTORY)
    while true:
      let symbols = toSeq(i.scope.symbols.keys)
      ed.completionCallback = proc(ed: LineEditor): seq[string] =
        return ed.getCompletions(symbols)
      # evaluate prompt
      i.push("prompt".newSym)
      let vals = i.expect("string")
      let v = vals[0] 
      let prompt = v.getString()
      line = ed.readLine(prompt)
      let r = i.interpret($line)
      if $line != "":
        i.printResult(r)

  proc minRepl*() = 
    var i = newMinInterpreter(filename = "<repl>")
    i.minRepl()

proc minSimpleRepl*() = 
  var i = newMinInterpreter(filename = "<repl>")
  i.minSimpleRepl()
    
when isMainModule:

  import 
    parseopt, 
    core/consts

  var REPL = false
  var SIMPLEREPL = false
  var INSTALL = false
  var UNINSTALL = false
  var COMPILE = false
  var libfile = ""
  var exeName = "min"
  var installOpt = "\n    -—install:<lib>           Install dynamic library file <lib>\n" 
  var uninstallOpt = "\n    —-uninstall:<lib>         Uninstall dynamic library file <lib>\n"
  var iOpt = "\n    -i, --interactive         Start $1 shell (with advanced prompt)\n"
  when defined(lite):
    exeName = "litemin"
  when defined(mini):
    installOpt = ""
    uninstallOpt = ""
    iOpt = ""
    exeName = "minimin"

  let usage* = """  $exe v$version - a tiny concatenative programming language
  (c) 2014-2020 Fabio Cevasco
  
  Usage:
    $exe [options] [filename]

  Arguments:
    filename  A $exe file to interpret or compile (default: STDIN).
  Options:$installOpt$uninstallOpt
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
      "installOpt", installOpt, 
      "uninstallOpt", uninstallOpt, 
      "iOpt", iOpt
  ]

  var file, s: string = ""
  var args = newSeq[string](0)
  setLogFilter(lvlNotice)
  
  for kind, key, val in getopt():
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
            for f in walkDirRec(val):
              if f.endsWith(".min"):
                MINMODULES.add f
          of "prelude", "p":
            customPrelude = val
          of "log", "l":
            if file == "":
              var val = val
              setLogLevel(val)
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
            if file == "":
              REPL = true
          of "interactive-simple", "j":
            if file == "":
              SIMPLEREPL = true
          of "install":
            if file == "":
              INSTALL = true
              libfile = val
          of "uninstall":
            if file == "":
              UNINSTALL = true
              libfile = val
          else:
            discard
      else:
        discard
  var op = "interpret"
  if COMPILE:
    op = "compile"
  if s != "":
    minStr(s)
  elif file != "":
    minFile file, op
  elif INSTALL:
    if not libfile.fileExists:
      fatal("Dynamic library file not found:" & libfile)
      quit(4)
    try:
      libfile.copyFile(MINLIBS/libfile.extractFilename)
    except:
      fatal("Unable to install library file: " & libfile)
      quit(5)
    notice("Dynamic linbrary installed successfully: " & libfile.extractFilename)
    quit(0)
  elif UNINSTALL:
    if not (MINLIBS/libfile.extractFilename).fileExists:
      fatal("Dynamic library file not found:" & libfile)
      quit(4)
    try:
      removeFile(MINLIBS/libfile.extractFilename)
    except:
      fatal("Unable to uninstall library file: " & libfile)
      quit(6)
    notice("Dynamic linbrary uninstalled successfully: " & libfile.extractFilename)
    quit(0)
  elif REPL:
    when defined(mini):
      minSimpleRepl()
    else:
      minRepl()
    quit(0)
  elif SIMPLEREPL:
    minSimpleRepl()
    quit(0)
  else:
    minFile stdin, "stdin", op
