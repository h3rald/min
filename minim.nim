import streams, critbits, parseopt2, strutils, os, json
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

const USE_LINENOISE* = false

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


var CURRSCOPE*: ref MinScope

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

when USE_LINENOISE:
  # TODO: rewrite
  proc completionCallback*(str: cstring, completions: ptr linenoiseCompletions) {.cdecl.}= 
    var words = ($str).split(" ")
    var w = if words.len > 0: words.pop else: ""
    var sep = ""
    if words.len > 0:
      sep = " "
    if w.startsWith("'"):
      for s in CURRSCOPE.symbols.keys:
        if startsWith("'$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "'" & s
      return
    if w.startsWith("~"):
      for s in CURRSCOPE.symbols.keys:
        if startsWith("~$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "~" & s
      return
    if w.startsWith("@"):
      for s in CURRSCOPE.symbols.keys:
        if startsWith("@$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "@" & s
      return
    if w.startsWith(">"):
      for s in CURRSCOPE.symbols.keys:
        if startsWith(">$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & ">" & s
      return
    if w.startsWith("<"):
      for s, v in MINIMSYMBOLS.readFile.parseJson.pairs:
        if startsWith("<$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "<" & s
      return
    if w.startsWith("*"):
      for s in CURRSCOPE.symbols.keys:
        if startsWith("*$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "*" & s
      return
    if w.startsWith("$"):
      for s,v in envPairs():
        if startsWith("$$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "$" & s
      return
    if w.startsWith("\""):
      for c,s in walkDir(getCurrentDir(), true):
        if startsWith("\"$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "\"" & s & "\""
      return
    let execs = getExecs()
    if w.startsWith("!"):
      for s in execs:
        if startsWith("!$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "!" & s
    if w.startsWith("&"):
      for s in execs:
        if startsWith("&$1"%s, w):
          linenoiseAddCompletion completions, words.join(" ") & sep & "&" & s
    for s in CURRSCOPE.symbols.keys:
      if s.startsWith(w):
        linenoiseAddCompletion completions, words.join(" ") & sep & s

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
  var ed = initEditor()
  while true:
    #when USE_LINENOISE:
      #CURRSCOPE = i.scope
      #linenoiseSetCompletionCallback completionCallback
      #discard linenoiseHistorySetMaxLen(1000)
      #discard linenoiseHistoryLoad(MINIMHISTORY)
    line = ed.readLine(": ")
    #if $line != "(null)":
    #  discard linenoiseHistorySave(MINIMHISTORY)
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
