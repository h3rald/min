import 
  streams, 
  critbits, 
  parseopt2, 
  strutils, 
  os, 
  json, 
  sequtils,
  algorithm
import 
  core/linedit,
  core/consts,
  core/parser, 
  core/value, 
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

var REPL = false
var DEBUGGING = false
const PRELUDE* = "prelude.min".slurp.strip
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

proc stdLib(i: In) =
  i.lang_module
  i.io_module
  i.logic_module
  i.num_module
  i.str_module
  i.sys_module
  i.time_module
  i.fs_module
  i.crypto_module
  i.eval PRELUDE
  if not MINIMSYMBOLS.fileExists:
    MINIMSYMBOLS.writeFile("{}")
  if not MINIMHISTORY.fileExists:
    MINIMHISTORY.writeFile("")
  if not MINIMRC.fileExists:
    MINIMRC.writeFile("")
  i.eval MINIMRC.readFile()

proc minimStream(s: Stream, filename: string, debugging = false) =
  var i = newMinInterpreter(debugging)
  i.pwd = filename.parentDir
  i.stdLib()
  i.open(s, filename)
  discard i.parser.getToken() 
  i.interpret()
  i.close()

proc minimString*(buffer: string, debugging = false) =
  minimStream(newStringStream(buffer), "input", debugging)

proc minimFile*(filename: string, debugging = false) =
  var stream = newFileStream(filename, fmRead)
  if stream == nil:
    stderr.writeLine("Error - Cannot read from file: "& filename)
    stderr.flushFile()
  minimStream(stream, filename, debugging)

proc minimFile*(file: File, filename="stdin", debugging = false) =
  var stream = newFileStream(stdin)
  if stream == nil:
    stderr.writeLine("Error - Cannot read from "& filename)
    stderr.flushFile()
  minimStream(stream, filename, debugging)

proc minimRepl*(i: var MinInterpreter) =
  i.stdLib()
  var s = newStringStream("")
  i.open(s, "")
  var line: string
  echo "$1 v$2" % [appname, version]
  var ed = initEditor(historyFile = MINIMHISTORY)
  i.apply(i.scope.getSymbol("startup"))
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
      i.interpret()
    except:
      stderr.writeLine getCurrentExceptionMsg()
    finally:
      if i.stack.len > 0:
        let last = i.stack[i.stack.len - 1]
        let n = $i.stack.len
        if last.isQuotation and last.qVal.len > 1:
          echo "{$1} -> (" % n
          for item in last.qVal:
            echo  "         " & $item
          echo " ".repeat(n.len) & "      )"
        else:
          echo "{$1} -> $2" % [$i.stack.len, $i.stack[i.stack.len - 1]]
      else:
        echo "{0} --"

proc minimRepl*(debugging = false) = 
  var i = newMinInterpreter(debugging)
  i.minimRepl

    
###

var file, s: string = ""

for kind, key, val in getopt():
  case kind:
    of cmdArgument:
      file = key
    of cmdLongOption, cmdShortOption:
      case key:
        of "debug", "d":
          DEBUGGING = true
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
  minimString(s, DEBUGGING)
elif file != "":
  minimFile file, DEBUGGING
elif REPL:
  minimRepl DEBUGGING
  quit(0)
else:
  minimFile stdin, "stdin", DEBUGGING
