import streams, strutils, critbits
import 
  types, 
  parser,
  ../vendor/linenoise

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

var ROOT*: ref MinScope = new MinScope

ROOT.name = "ROOT"

proc getSymbol*(scope: ref MinScope, key: string): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif not scope.parent.isNil:
    return scope.parent.getSymbol(key)

proc getSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif not scope.parent.isNil:
    return scope.parent.getSigil(key)

proc newMinInterpreter*(debugging = false): MinInterpreter =
  var st:MinStack = newSeq[MinValue](0)
  #var scope: ref MinScope = new MinScope
  #scope.parent = ROOT
  var pr:MinParser
  var i:MinInterpreter = MinInterpreter(
    filename: "input", 
    parser: pr, 
    stack: st,
    scope: ROOT,
    debugging: debugging, 
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc error*(i: MinInterpreter, status: MinError, message = "") =
  var msg = if message == "": ERRORS[status] else: message
  if i.filename == "":
    stderr.writeLine("`$1`: Error - $2" % [i.currSym.symVal, msg])
  else:
    stderr.writeLine("$1 [$2,$3] `$4`: Error - $5" % [i.filename, $i.currSym.line, $i.currSym.column, i.currSym.symVal, msg])
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
    stderr.writeLine("-- " & i.dump & $value)

proc push*(i: var MinInterpreter, val: MinValue) = 
  i.debug val
  if val.kind == minSymbol:
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    let symbolProc = i.scope.getSymbol(symbol)
    if not symbolProc.isNil:
      try:
        symbolProc(i) 
      except:
        i.error(errSystem, getCurrentExceptionMsg())
    else:
      let sigilProc = i.scope.getSigil(sigil)
      if symbol.len > 1 and not sigilProc.isNil:
        let sym = symbol[1..symbol.len-1]
        try:
          i.stack.add(MinValue(kind: minString, strVal: sym))
          sigilProc(i) 
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
    stderr.writeLine getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc load*(i: var MinInterpreter, s: string) =
  let fn = i.filename
  try:
    i.open(newStringStream(s.readFile), s)
    discard i.parser.getToken() 
    i.interpret()
  except:
    stderr.writeLine getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc apply*(i: var MinInterpreter, symbol: string) =
  i.scope.symbols[symbol](i)

proc copystack*(i: var MinInterpreter): MinStack =
  var s = newSeq[MinValue](0)
  for i in i.stack:
    s.add i
  return s

var INTERPRETER* = newMinInterpreter()
