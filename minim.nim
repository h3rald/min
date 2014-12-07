import streams, tables, parseopt2, strutils
import parser, interpreter, primitives, utils, linenoise


const version* = "0.1.0"
var debugging = false
var repl = false
const prelude = "prelude.min".slurp.strip

let usage* = "  MiNiM v" & version & " - a tiny concatenative system programming language" & """

  (c) 2014 Fabio Cevasco
  
  Usage:
    minim [options] [filename]

  Arguments:
    filename  A minim file to interpret (default: STDIN).
  Options:
    -e, --evaluate    Evaluate a minim program inline
    -h, --help        Print this help
    -v, --version     Print the program version
    -i, --interactive Starts MiNiM's Read Evel Print Loop"""

proc minimStream(s: PStream, filename: string) =
  var i = newMinInterpreter(debugging)
  i.eval prelude
  i.open(s, filename)
  discard i.parser.getToken() 
  i.interpret()
  i.close()

proc handleReplCtrlC() {.noconv.}=
  echo "\n-> Exiting..."
  quit(0)

proc minimString*(buffer: string) =
    minimStream(newStringStream(buffer), "input")

proc minimFile*(filename: string) =
  var stream = newFileStream(filename, fmRead)
  if stream == nil:
    stderr.writeln("Error - Cannot read from file: "& filename)
    stderr.flushFile()
  minimStream(stream, filename)

proc minimFile*(file: TFile, filename="stdin") =
  var stream = newFileStream(stdin)
  if stream == nil:
    stderr.writeln("Error - Cannot read from "& filename)
    stderr.flushFile()
  minimStream(stream, filename)

proc minimRepl*() = 
  var i = newMinInterpreter(debugging)
  var s = newStringStream("")
  i.open(s, "")
  setControlCHook(handleReplCtrlC)
  echo "MiNiM v"&version&" - REPL initialized."
  i.eval prelude
  echo "Prelude loaded."
  echo "-> Press Ctrl+C to exit."
  var line: string
  while true:
    stdout.write(": ")
    line = stdin.readLine()
    s.writeln(line)
    i.parser.buf = $i.parser.buf & line
    i.parser.bufLen = i.parser.buf.len
    discard i.parser.getToken() 
    try:
      i.interpret()
    except:
      warn getCurrentExceptionMsg()
    finally:
      stdout.write "-> "
      echo i.dump
    
###

var file, str: string = ""

for kind, key, val in getopt():
  case kind:
    of cmdArgument:
      file = key
    of cmdLongOption, cmdShortOption:
      case key:
        of "debug", "d":
          debugging = true
        of "evaluate", "e":
          str = val
        of "help", "h":
          echo usage
          quit(0)
        of "version", "v":
          echo version
        of "interactive", "i":
          repl = true
    else:
      discard

if str != "":
  minimString(str)
elif file != "":
  minimFile file
elif repl:
  minimRepl()
  quit(0)
else:
  minimFile stdin

