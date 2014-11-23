import streams, strutils, tables
import parser

type 
  TMinInterpreter* = object
    stack: TMinStack
    parser*: TMinParser
    currSym: TMinValue
    filename: string
  TMinOperator* = proc (i: var TMinInterpreter)
  TMinError* = enum
    errParser,
    errGeneric,
    errEmptyStack,
    errNoQuotation,
    errUndefined,
    errIncorrect,
    errTwoNumbersRequired,
    errDivisionByZero


const ERRORS: array [TMinError, string] = [
  "A parsing error occurred",
  "A generic error occurred",
  "The stack is empty", 
  "Quotation not found on the stack",
  "Symbol undefined",
  "Incorrect items on the stack",
  "Two numbers are required on the stack",
  "Division by zero"
]

var SYMBOLS* = initTable[string, TMinOperator]()

proc newMinInterpreter*(): TMinInterpreter =
  var s:TMinStack = newSeq[TMinValue](0)
  var p:TMinParser
  var i:TMinInterpreter = TMinInterpreter(filename: "input", parser: p, stack: s, currSym: TMinValue(first: 0, last: 0, line: 0, kind: minSymbol, symVal: ""))
  return i

proc error*(i: TMinInterpreter, status: TMinError, message = "") =
  var msg = if message == "": ERRORS[status] else: message
  stderr.writeln("$1[$2,$3] `$4`: Error - $5" %[i.filename, $i.currSym.line, $i.currSym.last, i.currSym.symVal, msg])
  quit(int(status))

proc open*(i: var TMinInterpreter, stream:PStream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: var TMinInterpreter) = 
  i.parser.close();

proc push*(i: var TMinInterpreter, val: TMinValue) = 
  if val.kind == minSymbol:
    i.currSym = val
    if SYMBOLS.hasKey val.symVal:
      SYMBOLS[val.symVal](i) 
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

proc dump*(i: TMinInterpreter) =
  stdout.write "[ "
  for item in i.stack:
    item.print
    stdout.write " "
  stdout.writeln "]"

proc interpret*(i: var TMinInterpreter) = 
  var val: TMinValue
  while i.parser.token != tkEof: 
    try:
      val = i.parser.parseMinValue
    except:
      i.error errParser, getCurrentExceptionMsg()
    i.push val
