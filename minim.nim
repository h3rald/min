import streams, critbits, parseopt2, strutils, os, json, sequtils
import 
  core/linedit,
  core/types,
  core/parser, 
  core/interpreter, 
  core/utils
import 
  lib/min_lang, 
  lib/min_stack, 
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
let usage* = "  MiNiM v" & version & " - a tiny concatenative programming language" & """

  (c) 2014-2016 Fabio Cevasco
  
  Usage:
    minim [options] [filename]

  Arguments:
    filename  A minim file to interpret (default: STDIN).
  Options:
    -e, --evaluate    Evaluate a minim program inline
    -h, --help        Print this help
    -v, --version     Print the program version
    -i, --interactive Start MiNiM Shell"""


proc getExecs(): seq[string] =
  var res = newSeq[string](0)
  let getFiles = proc(dir: string) =
    for c, s in walkDir(dir, true):
      if (c == pcFile or c == pcLinkToFile) and not res.contains(s):
        res.add s
  getFiles(getCurrentDir())
  for dir in "PATH".getEnv.split(PathSep):
    getFiles(dir)
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
    return toSeq(MINIMSYMBOLS.readFile.parseJson.pairs).mapIt(">" & $it[0])
  if word.startsWith("$"):
    return toSeq(envPairs()).mapIt("$" & $it[0])
  if word.startsWith("!"):
    return getExecs().mapIt("!" & $it[0])
  if word.startsWith("&"):
    return getExecs().mapIt("&" & $it[0])
  if word.startsWith("\""):
    var f = word[1..^1]
    if f == "":
      f = getCurrentDir().replace("\\", "/")  
      return toSeq(f.walkDir).mapIt("\"$1\"" % it.path.replace("\\", "/"))
    elif f.dirExists:
      f = f.replace("\\", "/")
      return toSeq(f.walkDir).mapIt("\"$1\"" % it.path.replace("\\", "/"))
    else:
      let dir = f.parentDir
      if dir.existsDir:
        return toSeq(dir.walkDir).filterIt(it.path.startsWith(f)).mapIt("\"$1\"" % it.path.replace("\\", "/"))
  return symbols

proc stdLib(i: In) =
  i.lang_module
  i.io_module
  i.logic_module
  i.num_module
  i.stack_module
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
  echo "MiNiM Shell v$1" % version
  echo "-> Type 'exit' or 'quit' to exit."
  var ed = initEditor(historyFile = MINIMHISTORY)
  KEYMAP["ctrl+s"] = proc (ed: var LineEditor) =
    echo "hello"
    when defined(windows):
      discard execShellCmd("cls")
    else:
      discard execShellCmd("clear")
  while true:
    let symbols = toSeq(i.scope.symbols.keys)
    completionCallback = proc(ed: LineEditor): seq[string] {.locks: 0.}=
      return ed.getCompletions(symbols)
    line = ed.readLine(": ")
    i.parser.buf = $i.parser.buf & $line
    i.parser.bufLen = i.parser.buf.len
    discard i.parser.getToken() 
    try:
      i.interpret()
    except:
      warn getCurrentExceptionMsg()
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
