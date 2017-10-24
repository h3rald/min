import 
  streams, 
  critbits, 
  parseopt2, 
  strutils, 
  os, 
  json, 
  sequtils,
  algorithm,
  logging,
  dynlib

import 
  packages/nimline/nimline,
  packages/niftylogger,
  core/consts,
  core/parser, 
  core/value, 
  core/scope,
  core/interpreter, 
  core/utils
import 
  lib/min_lang, 
  lib/min_stack, 
  lib/min_seq, 
  lib/min_num,
  lib/min_str,
  lib/min_logic,
  lib/min_time, 
  lib/min_io,
  lib/min_sys,
  lib/min_fs

when not defined(lite):
  import lib/min_crypto

export 
  parser,
  interpreter,
  utils,
  niftylogger,
  value,
  scope,
  min_lang

const PRELUDE* = "prelude.min".slurp.strip

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
  if not MINSYMBOLS.fileExists:
    MINSYMBOLS.writeFile("{}")
  if not MINHISTORY.fileExists:
    MINHISTORY.writeFile("")
  if not MINRC.fileExists:
    MINRC.writeFile("")
  i.lang_module
  i.stack_module
  i.seq_module
  i.io_module
  i.logic_module
  i.num_module
  i.str_module
  i.sys_module
  i.time_module
  i.fs_module
  when not defined(lite):
    i.crypto_module
  i.eval PRELUDE, "<prelude>"
  i.eval MINRC.readFile()
  i.eval "\"prompt\" unseal"

type
  setupProc = proc(
      defineProc: proc(i: In): ref MinScope,
      finalizeProc: proc(scope: ref MinScope, name: string),
      symbolProc: proc(scope: ref MinScope, sym: string, p: MinOperatorProc),
      expectProc: proc(i: var MinInterpreter, elements: varargs[string]): seq[MinValue],
      pushProc: proc(i: In, val: MinValue)
    ): string {.nimcall.}
  libProc = proc(
      i: In
    ) {.nimcall.}
proc dynLib*(i: In) =
  var
    dll: LibHandle
    setup: setupProc
  dll = loadLib("./dynlibs/libmindyn.so")
  if dll != nil:
    let setupAddr = dll.symAddr("setup")
    if setupAddr != nil:
      setup = cast[setupProc](setupAddr)

  if setup != nil:
    let
      libName = setup(define, finalize, symbol, expect, push)
      libAddr = dll.symAddr(libName)
    if libAddr != nil:
      var lib = cast[libProc](libAddr)
      i.lib
      echo "Loaded dynlib"
    else:
      echo "Wasn't able to load " & libName & "(i: In) from DLL."
  else:
    echo "Wasn't able to load setup() from DLL."

proc interpret*(i: In, s: Stream) =
  i.stdLib()
  i.dynLib()
  i.open(s, i.filename)
  discard i.parser.getToken() 
  try:
    i.interpret()
  except:
    discard
  i.close()

proc minStream(s: Stream, filename: string) = 
  var i = newMinInterpreter(filename = filename)
  i.pwd = filename.parentDir
  i.interpret(s)

proc minString*(buffer: string) =
  minStream(newStringStream(buffer), "input")

proc minFile*(filename: string) =
  var stream = newFileStream(filename, fmRead)
  if stream == nil:
    fatal("Cannot read from file: "& filename)
    quit(3)
  minStream(stream, filename)

proc minFile*(file: File, filename="stdin") =
  var stream = newFileStream(stdin)
  if stream == nil:
    fatal("Cannot read from file: "& filename)
    quit(3)
  minStream(stream, filename)

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

proc minRepl*(i: var MinInterpreter) =
  i.stdLib()
  i.dynLib()
  var s = newStringStream("")
  i.open(s, "<repl>")
  var line: string
  #echo "$1 v$2" % [appname, version]
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
    i.parser.bufpos = 0
    i.parser.buf = $line
    i.parser.bufLen = i.parser.buf.len
    discard i.parser.getToken() 
    try:
      i.printResult i.interpret()
    except:
      discard

proc minRepl*() = 
  var i = newMinInterpreter(filename = "<repl>")
  i.minRepl
    
when isMainModule:

  var REPL = false

  let usage* = """  $1 v$2 - a tiny concatenative shell and programming language
  (c) 2014-2017 Fabio Cevasco
  
  Usage:
    min [options] [filename]

  Arguments:
    filename  A $1 file to interpret (default: STDIN).
  Options:
    -e, --evaluate    Evaluate a $1 program inline
    -h, --help        Print this help
    -v, --version     Print the program version
    -i, --interactive Start $1 shell""" % [appname, version]

  var file, s: string = ""
  setLogFilter(lvlNotice)
  
  for kind, key, val in getopt():
    case kind:
      of cmdArgument:
        file = key
      of cmdLongOption, cmdShortOption:
        case key:
          of "log", "l":
            var val = val
            setLogLevel(val)
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
    minString(s)
  elif file != "":
    minFile file
  elif REPL:
    minRepl()
    quit(0)
  else:
    minFile stdin, "stdin"
