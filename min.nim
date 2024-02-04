import
  std/[streams,
  strutils,
  sequtils,
  times,
  os,
  logging]
import
  minpkg/core/[niftylogger,
  baseutils,
  env,
  parser,
  value,
  scope,
  interpreter,
  stdlib,
  shell,
  utils,
  mmm]
import
  minpkg/lib/[
    min_global
  ]

export
  env,
  parser,
  interpreter,
  utils,
  value,
  shell,
  scope,
  stdlib,
  min_global,
  niftylogger

var NIMOPTIONS* = ""
var MINMODULES* = newSeq[string](0)
var MMM*: MinModuleManager

if logging.getHandlers().len == 0:
  newNiftyLogger().addHandler()

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  i.open(s, i.filename)
  discard i.parser.getToken()
  try:
    i.interpret()
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
      let cmd = "nim c --threadAnalysis:off --mm:refc $#$#" % [NIMOPTIONS&" ", nimFile]
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
    minpkg/core/meta

  var REPL = false
  var MODULEPATH = ""
  var GLOBAL = false

  proc resolveFile(file: string): string =
    if (file.endsWith(".min") or file.endsWith(".mn")) and fileExists(file):
      return file
    elif fileExists(file&".min"):
      return file&".min"
    elif fileExists(file&".mn"):
      return file&".mn"
    return ""

  proc executeMmmCmd(cmd: proc (): void) =
    try:
      MMM.setup()
      cmd()
      quit(0)
    except CatchableError:
      error getCurrentExceptionMsg()
      debug getCurrentException().getStackTrace()
      quit(10)

  let usage* = """  $exe v$version - a small but practical concatenative programming language
  (c) 2014-$year Fabio Cevasco
  
  Usage:
    $exe [options] [filename | command] [...comamand-arguments]

  Arguments:
    filename  A $exe file to interpret or compile 
    command   A command to execute
  Commands:
    compile <file>.min             Compile <file>.min.
    eval <string>                  Evaluate <string> as a min program.
    help <symbol|sigil>            Print the help contents related to <symbol|sigil>.
    init                           Sets up the current directory as a managed min module.
    install [<module>@<version>]   Install the specified managed min module or all dependent modules.
    uninstall [<module>@<version>] Uninstall the specified managed min module or all dependent modules.
    update [<module>@<version>]    Update the specified managed min module or all dependent modules.
    run <mmm>                      Executes the main symbol exposed by the specified min managed module,
                                   downloading it and installing it globally if necessary.
    search [...terms...]           Search for a managed min module matching the specified terms.  
    list                           List all managed min modules installed in the local directory or globally.
  Options:
    -a, --asset-path          Specify a directory containing the asset files to include in the
                              compiled executable (if -c is set)
    -d, --dev                 Enable "development mode" (runtime checks)
    -g, --global              Execute the specified command (install or uninstall) globally.
    -h, --help                Print this help
    -i, --interactive         Start $exe shell (with advanced prompt, default if no file specidied)"
    -j, --interactive-simple  Start $exe shell (without advanced prompt)
    -l, --log                 Set log level (debug|info|notice|warn|error|fatal)
                              Default: notice
    -m, --module-path         Specify a directory containing the .min files to include in the
                              compiled executable (if -c is set)
    -n, --passN               Pass options to the nim compiler (if -c is set)
    -p, --prelude:<file.min>  If specified, it loads <file.min> instead of the default prelude code
    -r, --registry:<url>      If specified, uses the specified url as MMM registry
    -v, —-version             Print the program version""" % [
      "exe", pkgName,
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
          of "global", "g":
            GLOBAL = true
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
          of "registry", "r":
            MMMREGISTRY = val
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
          logging.error "No file was specified."
          quit(8)
        fn = resolveFile(args[1])
        if fn == "":
          logging.error "File '$#' does not exist." % [args[1]]
          quit(9)
      elif file == "eval":
        if args.len < 2:
          logging.error "No string to evaluate was specified."
          quit(9)
        minStr args[1]
        quit(0)
      elif file == "help":
        if args.len < 2:
          logging.error "No symbol to lookup was specified."
          quit(9)
        minStr("\"$#\" help" % [args[1]])
        quit(0)
      elif file == "init":
        executeMmmCmd(proc () = MMM.init())
      elif file == "run":
        if args.len < 1:
          logging.error "No script was specified."
          quit(8)
        MMM.setup()
        var script: string
        try:
          script = MMM.generateRunScript(args[1])
        except CatchableError:
          error getCurrentExceptionMsg()
          debug getCurrentException().getStackTrace()
          quit(10)
        minStr(script)
        quit(0)
      elif file == "install":
        if args.len < 2:
          executeMmmCmd(proc () = MMM.install())
        if args.len == 2:
          executeMmmCmd(proc () = MMM.install(args[1], GLOBAL))
        let name = args[1]
        let version = args[2]
        executeMmmCmd(proc () = MMM.install(name, version, GLOBAL))
      elif file == "uninstall":
        if args.len < 2:
          executeMmmCmd(proc () = MMM.uninstall())
        if args.len == 2:
          executeMmmCmd(proc () = MMM.uninstall(args[1], GLOBAL))
        let name = args[1]
        let version = args[2]
        executeMmmCmd(proc () = MMM.uninstall(name, version, GLOBAL))
      elif file == "update":
        if args.len < 2:
          executeMmmCmd(proc () = MMM.update())
        if args.len == 2:
          executeMmmCmd(proc () = MMM.update(args[1], GLOBAL))
        let name = args[1]
        let version = args[2]
        executeMmmCmd(proc () = MMM.update(name, version, GLOBAL))
      elif file == "search":
        var str = ""
        if args.len > 1:
          str = args[1 .. ^1].join(" ")
        executeMmmCmd(proc () = MMM.search(str))
      elif file == "list":
        if GLOBAL:
          executeMmmCmd(proc () = MMM.list(MMM.globalDir))
        else:
          executeMmmCmd(proc () = MMM.list(MMM.localDir))
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
