import streams, strutils, tables
import parser, ../vendor/linenoise

type 
  MinInterpreter* = object
    stack*: MinStack
    parser*: MinParser
    currSym: MinValue
    filename*: string
    debugging*: bool 
    evaluating*: bool 
  MinOperator* = proc (i: var MinInterpreter)
  MinSigil* = proc (i: var MinInterpreter, sym: string)
  MinError* = enum
    errSystem,
    errParser,
    errGeneric,
    errEmptyStack,
    errNoQuotation,
    errUndefined,
    errIncorrect,
    errTwoNumbersRequired,
    errDivisionByZero


const ERRORS: array [MinError, string] = [
  "A system error occurred",
  "A parsing error occurred",
  "A generic error occurred",
  "Insufficient items on the stack", 
  "Quotation not found on the stack",
  "Symbol undefined",
  "Incorrect items on the stack",
  "Two numbers are required on the stack",
  "Division by zero"
]

var SYMBOLS* = initTable[string, MinOperator]()
var SIGILS* = initTable[string, MinOperator]()

proc newMinInterpreter*(debugging = false): MinInterpreter =
  var s:MinStack = newSeq[MinValue](0)
  var p:MinParser
  var i:MinInterpreter = MinInterpreter(filename: "input", parser: p, stack: s, debugging: debugging, currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: ""))
  return i

proc error*(i: MinInterpreter, status: MinError, message = "") =
  var msg = if message == "": ERRORS[status] else: message
  if i.filename == "":
    stderr.writeln("`$1`: Error - $2" %[i.currSym.symVal, msg])
  else:
    stderr.writeln("$1 [$2,$3] `$4`: Error - $5" %[i.filename, $i.currSym.line, $i.currSym.column, i.currSym.symVal, msg])
    quit(int(status))

proc open*(i: var MinInterpreter, stream:Stream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: var MinInterpreter) = 
  i.parser.close();

proc dump*(i: MinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug(i: var MinInterpreter, value: MinValue) =
  if i.debugging: 
    stderr.writeln("-- " &i.dump & $value)

proc push*(i: var MinInterpreter, val: MinValue) = 
  i.debug val
  if val.kind == minSymbol:
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    if SYMBOLS.hasKey(val.symVal):
      try:
        SYMBOLS[val.symVal](i) 
      except:
        i.error(errSystem, getCurrentExceptionMsg())
    else:
      if SIGILS.hasKey(sigil) and symbol.len > 1:
        let sym = symbol[1..symbol.len-1]
        try:
          i.stack.add(MinValue(kind: minString, strVal: sym))
          SIGILS[sigil](i) 
        except:
          i.error(errSystem, getCurrentExceptionMsg())
      else:
        i.error(errUndefined, "Undefined symbol: '"&val.symVal&"'")
  else:
    i.stack.add(val)

proc push*(i: var MinInterpreter, q: seq[MinValue]) =
  for e in q:
    i.push e

proc pop*(i: var MinInterpreter): MinValue =
  if i.stack.len > 0:
    return i.stack.pop
  else:
    i.error(errEmptyStack)

proc peek*(i: MinInterpreter): MinValue = 
  if i.stack.len > 0:
    return i.stack[i.stack.len-1]
  else:
    i.error(errEmptyStack)

proc interpret*(i: var MinInterpreter) = 
  var val: MinValue
  while i.parser.token != tkEof: 
    try:
      val = i.parser.parseMinValue
    except:
      i.error errParser, getCurrentExceptionMsg()
    i.push val

proc eval*(i: var MinInterpreter, s: string) =
  let fn = i.filename
  try:
    i.open(newStringStream(s), "eval")
    discard i.parser.getToken() 
    i.interpret()
  except:
    stderr.writeln getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc load*(i: var MinInterpreter, s: string) =
  let fn = i.filename
  try:
    i.open(newStringStream(s.readFile), s)
    discard i.parser.getToken() 
    i.interpret()
  except:
    stderr.writeln getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc apply*(i: var MinInterpreter, symbol: string) =
  SYMBOLS[symbol](i)

proc copystack*(i: var MinInterpreter): MinStack =
  var s = newSeq[MinValue](0)
  for i in i.stack:
    s.add i
  return s


