import streams, critbits, parseopt2, strutils, os, asyncdispatch
import 
  core/types,
  core/parser, 
  core/interpreter, 
  core/utils,
  core/server,
  vendor/linenoise
import 
  lib/min_lang, 
  lib/min_stack, 
  lib/min_num,
  lib/min_str,
  lib/min_logic,
  lib/min_time, 
  lib/min_io,
  lib/min_sys,
  lib/min_comm

const version* = "1.0.0-dev"
var REPL = false
var DEBUGGING = false
var PORT = 7500
var ADDRESS = "0.0.0.0"
var SRVTHREAD: Thread[ref MinLink]
var SERVER = false
var HOSTNAME = ""

const
  USE_LINENOISE = true

const PRELUDE* = "lib/prelude.min".slurp.strip

let usage* = "  MiNiM v" & version & " - a tiny concatenative programming language" & """

  (c) 2014-2016 Fabio Cevasco
  
  Usage:
    minim [options] [filename]

  Arguments:
    filename  A minim file to interpret (default: STDIN).
  Options:
    -e, --evaluate    Evaluate a minim program inline
    -h, --help        Print this help
    -a, --address     Specify server address (default: 0.0.0.0)
    -p, --port        Specify server port (default: 7500)
    -s, --server      Start server remote command execution
    -v, --version     Print the program version
    -i, --interactive Start MiNiM's Read Eval Print Loop"""


var CURRSCOPE*: ref MinScope

proc completionCallback*(str: cstring, completions: ptr linenoiseCompletions) {.cdecl.}= 
  var words = ($str).split(" ")
  var w = if words.len > 0: words.pop else: ""
  var sep = ""
  if words.len > 0:
    sep = " "
  for s in CURRSCOPE.symbols.keys:
    if startsWith(s, w):
      linenoiseAddCompletion completions, words.join(" ") & sep & s
proc prompt(s: string): string = 
  var res = linenoise(s)
  discard $linenoiseHistoryAdd(res)
  return $res


proc stdLib(i: In) =
  i.lang_module
  i.io_module
  i.logic_module
  i.num_module
  i.stack_module
  i.str_module
  i.sys_module
  i.time_module
  i.comm_module
  i.eval PRELUDE
  

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
  echo "Terminal initialized."
  echo "-> Type 'exit' or 'quit' to exit."
  var line: string
  while true:
    when USE_LINENOISE:
      CURRSCOPE = i.scope
      linenoiseSetCompletionCallback completionCallback
    line = prompt(": ")
    i.parser.buf = $i.parser.buf & $line
    i.parser.bufLen = i.parser.buf.len
    discard i.parser.getToken() 
    try:
      i.interpret()
    except:
      warn getCurrentExceptionMsg()
    finally:
      stdout.write "-> "
      echo i.dump

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
        of "port", "p":
          PORT = val.parseInt
        of "address", "a":
          if val.strip.len > 0:
            ADDRESS = val
        of "server", "s":
          if val.strip.len > 0:
            HOSTNAME = val
          SERVER = true
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

if not cfgfile().existsFile:
  cfgfile().writeFile("{}")

if REPL or SERVER:
  echo "MiNiM v"&version

if s != "":
  minimString(s, DEBUGGING)
elif file != "":
  minimFile file, DEBUGGING
elif SERVER:
  var i = newMinInterpreter(DEBUGGING)
  let host = ADDRESS & ":" & $PORT
  if HOSTNAME == "":
    HOSTNAME = host
  var link = newMinLink(HOSTNAME, ADDRESS, PORT, i)
  i.link.checkHost()
  echo "Host '", HOSTNAME,"' started on ", HOSTNAME
  proc srv(link: ref MinLink) =
    link.init()
    runForever()
  createThread(SRVTHREAD, srv, link)
  i.minimRepl
elif REPL:
  minimRepl DEBUGGING
  quit(0)
else:
  minimFile stdin, "stdin", DEBUGGING

if SERVER:
  joinThreads([SRVTHREAD])

