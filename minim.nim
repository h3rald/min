import streams, tables, parseopt2
import parser, interpreter, primitives


const version* = "0.1.0"

let usage* = "  MiNiM v" & version & " - a tiny concatenative programming language" & """

  (c) 2014 Fabio Cevasco
  
  Usage:
    minim [options] [filename]

  Arguments:
    filename  A minim file to interpret.
  Options:
    -e, --evaluate    Evaluate a minim program inline
    -h, --help        Print this help
    -v, --version     Print the program version"""

proc minimStream*(s: PStream, filename: string) =
  var i = newMinInterpreter()
  i.open(s, filename)
  discard i.parser.getToken() 
  i.interpret()
  i.close()

proc minimString*(buffer: string) =
    minimStream(newStringStream(buffer), "input")

proc minimFile*(filename: string) =
  var stream = newFileStream(filename, fmRead)
  if stream == nil:
    writeln(stderr, "Error - Cannot read from file: "& filename)
    flushFile(stderr)
  minimStream(stream, filename)

###

var file, str: string = ""

for kind, key, val in getopt():
  case kind:
    of cmdArgument:
      file = key
    of cmdLongOption, cmdShortOption:
      case key:
        of "evaluate", "e":
          str = val
        of "help", "h":
          echo usage
        of "version", "v":
          echo version
    else:
      discard

if str != "":
  minimString(str)
elif file != "":
  minimFile(file)
else:
  echo usage
