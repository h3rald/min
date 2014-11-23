import streams, strutils, tables
import parser

type 
  TMinInterpreter* = object
    stack: TMinStack
    parser*: TMinParser
    currSym: TMinValue
    filename: string
    debugging: bool 
    evaluating*: bool 
  TMinOperator* = proc (i: var TMinInterpreter)
  TMinError* = enum
    errSystem,
    errParser,
    errGeneric,
    errEmptyStack,
    errNoQuotation,
    errUndefined,
    errIncorrect,
    errTwoNumbersRequired,
    errDivisionByZero


const ERRORS: array [TMinError, string] = [
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

var SYMBOLS* = initTable[string, TMinOperator]()

proc newMinInterpreter*(debugging = false): TMinInterpreter =
  var s:TMinStack = newSeq[TMinValue](0)
  var p:TMinParser
  var i:TMinInterpreter = TMinInterpreter(filename: "input", parser: p, stack: s, debugging: debugging, currSym: TMinValue(first: 0, last: 0, line: 0, kind: minSymbol, symVal: ""))
  return i

proc error*(i: TMinInterpreter, status: TMinError, message = "") =
  var msg = if message == "": ERRORS[status] else: message
  if i.filename != "":
    stderr.writeln("$1[$2,$3] `$4`: Error - $5" %[i.filename, $i.currSym.line, $i.currSym.last, i.currSym.symVal, msg])
  else:
    stderr.writeln("`$1`: Error - $2" %[i.currSym.symVal, msg])
  quit(int(status))

proc open*(i: var TMinInterpreter, stream:PStream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: var TMinInterpreter) = 
  i.parser.close();

proc dump*(i: TMinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug(i: var TMinInterpreter, value: TMinValue) =
  if i.debugging: 
    stderr.writeln("-- " &i.dump & $value)

proc push*(i: var TMinInterpreter, val: TMinValue) = 
  i.debug val
  if val.kind == minSymbol:
    if not i.evaluating:
      i.currSym = val
    if SYMBOLS.hasKey(val.symVal):
      try:
        SYMBOLS[val.symVal](i) 
      except:
        i.error(errSystem, getCurrentExceptionMsg())
    else:
      i.error(errUndefined, "Undefined symbol: '"&val.symVal&"'")
  else:
    i.stack.add(val)

proc pop*(i: var TMinInterpreter): TMinValue =
  if i.stack.len > 0:
    return i.stack.pop
  else:
    i.error(errEmptyStack)

proc peek*(i: TMinInterpreter): TMinValue = 
  if i.stack.len > 0:
    return i.stack[i.stack.len-1]
  else:
    i.error(errEmptyStack)

proc interpret*(i: var TMinInterpreter) = 
  var val: TMinValue
  while i.parser.token != tkEof: 
    try:
      val = i.parser.parseMinValue
    except:
      i.error errParser, getCurrentExceptionMsg()
    i.push val
