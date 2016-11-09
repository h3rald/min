import 
  streams, 
  critbits, 
  parseopt2, 
  strutils, 
  os, 
  json, 
  sequtils,
  algorithm,
  logging
import 
  core/linedit,
  core/consts,
  core/parser, 
  core/value, 
  core/scope,
  core/interpreter, 
  core/utils,
  core/zip
import 
  lib/min_lang, 
  lib/min_num,
  lib/min_str,
  lib/min_logic,
  lib/min_time, 
  lib/min_io,
  lib/min_sys,
  lib/min_crypto,
  lib/min_fs

export 
  parser,
  interpreter,
  utils,
  value,
  scope,
  min_lang

const PRELUDE* = "prelude.min".slurp.strip

newConsoleLogger().addHandler()
newRollingFileLogger(MINIMLOG, fmtStr = verboseFmtStr).addHandler()

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

proc getCompletions(ed: LineEditor, symbols: seq[string]): seq[string] =
  var words = ed.lineText.split(" ")
  var word: string
  if words.len == 0:
    word = ed.lineText
  else:
    word = words[words.len-1]
  if word.startsWith("'"):
    return symbols.mapIt("'" & $it)
  elif word.startsWith("~"):
    return symbols.mapIt("~" & $it)
  if word.startsWith("@"):
    return symbols.mapIt("@" & $it)
  if word.startsWith(">"):
    return symbols.mapIt(">" & $it)
  if word.startsWith("*"):
    return symbols.mapIt("*" & $it)
  if word.startsWith("("):
    return symbols.mapIt("(" & $it)
  if word.startsWith("<"):
    return toSeq(MINIMSYMBOLS.readFile.parseJson.pairs).mapIt("<" & $it[0])
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
  if not MINIMSYMBOLS.fileExists:
    MINIMSYMBOLS.writeFile("{}")
  if not MINIMHISTORY.fileExists:
    MINIMHISTORY.writeFile("")
  if not MINIMRC.fileExists:
    MINIMRC.writeFile("")
  i.lang_module
  i.io_module
  i.logic_module
  i.num_module
  i.str_module
  i.sys_module
  i.time_module
  i.fs_module
  i.crypto_module
  i.eval PRELUDE, "<prelude>"
  i.eval MINIMRC.readFile()

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  i.open(s, i.filename)
  discard i.parser.getToken() 
  try:
    i.interpret()
  except:
    discard
  i.close()

proc minimStream(s: Stream, filename: string) = 
  var i = newMinInterpreter()
  i.pwd = filename.parentDir
  i.interpret(s)

proc minimString*(buffer: string) =
  minimStream(newStringStream(buffer), "input")

proc minimFile*(filename: string) =
  var stream = newFileStream(filename, fmRead)
  if stream == nil:
    error("Cannot read from file: "& filename)
    quit(100)
  minimStream(stream, filename)

proc minimFile*(file: File, filename="stdin") =
  var stream = newFileStream(stdin)
  if stream == nil:
    error("Cannot read from file: "& filename)
    quit(100)
  minimStream(stream, filename)

proc printResult(i: In, res: MinValue) =
  if res.isNil:
    return
  if i.stack.len > 0:
    let n = $i.stack.len
    if res.isQuotation and res.qVal.len > 1:
      echo "{$1} -> (" % n
      for item in res.qVal:
        echo  "         " & $item
      echo " ".repeat(n.len) & "      )"
    else:
      echo "{$1} -> $2" % [$i.stack.len, $i.stack[i.stack.len - 1]]

proc minimRepl*(i: var MinInterpreter) =
  i.stdLib()
  var s = newStringStream("")
  i.open(s, "")
  var line: string
  #echo "$1 v$2" % [appname, version]
  var ed = initEditor(historyFile = MINIMHISTORY)
  while true:
    let symbols = toSeq(i.scope.symbols.keys)
    ed.completionCallback = proc(ed: LineEditor): seq[string] =
      return ed.getCompletions(symbols)
    # evaluate prompt
    i.apply(i.scope.getSymbol("prompt"))
    var v: MinValue
    i.reqString(v)
    let prompt = v.getString()
    line = ed.readLine(prompt)
    i.parser.buf = $i.parser.buf & $line
    i.parser.bufLen = i.parser.buf.len
    discard i.parser.getToken() 
    try:
      i.printResult i.interpret()
    except:
      discard

proc minimRepl*() = 
  var i = newMinInterpreter()
  i.minimRepl
    
when isMainModule:

  var REPL = false

  let usage* = """  $1 v$2 - a tiny concatenative shell and programming language
  (c) 2014-2016 Fabio Cevasco
  
  Usage:
    minim [options] [filename]

  Arguments:
    filename  A $1 file to interpret (default: STDIN).
  Options:
    -e, --evaluate    Evaluate a $1 program inline
    -h, --help        Print this help
    -v, --version     Print the program version
    -i, --interactive Start $1 shell""" % [appname, version]

  var file, s: string = ""
  setLogFilter(lvlWarn)
  
  for kind, key, val in getopt():
    case kind:
      of cmdArgument:
        file = key
      of cmdLongOption, cmdShortOption:
        case key:
          of "log", "l":
            var val = val
            logLevel(val)
          of "evaluate", "e":
            s = val
          of "help", "h":
            echo usage
            quit(0)
          of "version", "v":
            echo version
            quit(0)
          of "interactive", "i":
            REPL = true
          else:
            discard
      else:
        discard
  
  if s != "":
    minimString(s)
  elif file != "":
    minimFile file
  elif REPL:
    minimRepl()
    quit(0)
  else:
    minimFile stdin, "stdin"
