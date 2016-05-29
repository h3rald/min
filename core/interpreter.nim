import streams, strutils, critbits, os
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
  "Runtime error",
  "Two numbers are required on the stack",
  "Division by zero"
]

var ROOT*: ref MinScope = new MinScope

ROOT.name = "ROOT"

proc fullname*(scope: ref MinScope): string =
  result = scope.name
  if not scope.parent.isNil:
    result = scope.parent.fullname & ":" & result

proc getSymbol*(scope: ref MinScope, key: string): MinOperator =
  #echo key, " - ", scope.symbols.hasKey(key)
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif not scope.parent.isNil:
    return scope.parent.getSymbol(key)

proc delSymbol*(scope: ref MinScope, key: string) =
  #echo key, " - ", scope.symbols.hasKey(key)
  if scope.symbols.hasKey(key):
    scope.symbols.excl(key)
  elif not scope.parent.isNil:
    scope.parent.delSymbol(key)

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator): bool {.discardable.}=
  result = false
  # check if a symbol already exists in parent scope
  if not scope.parent.isNil and scope.parent.symbols.hasKey(key):
    scope.parent.symbols[key] = value
    #echo "($1) SET EXISTING SYMBOL: $2" % [scope.parent.fullname, key]
    return true
  else:
    # Go up the scope chain and attempt to find the symbol
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value)
  if not result:
    # Define local variable
    #echo "($1) SET LOCAL SYMBOL: $2" % [scope.fullname, key]
    scope.symbols[key] = value
    return true

proc getSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif not scope.parent.isNil:
    return scope.parent.getSigil(key)

proc dump*(i: MinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug*(i: var MinInterpreter, value: MinValue) =
  if i.debugging: 
    stderr.writeLine("-- " & i.dump & $value)

proc debug*(i: var MinInterpreter, value: string) =
  if i.debugging: 
    stderr.writeLine("-- " & value)

template newScope*(i: In, id: string, q: MinValue, body: stmt): stmt {.immediate.}=
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope
  #i.debug "[scope] " & q.scope.fullname
  let scope = i.scope
  i.scope = q.scope
  body
  #i.debug "[scope] " & scope.fullname
  i.scope = scope

template newDisposableScope*(i: In, id: string, body: stmt): stmt {.immediate.}=
  var q = MinValue(kind: minQuotation, qVal: newSeq[MinValue](0))
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope
  q.scope.disposable = true
  #i.debug "[scope] " & q.scope.fullname
  let scope = i.scope
  i.scope = q.scope
  body
  #i.debug "[scope] " & scope.fullname
  i.scope = scope

proc newMinInterpreter*(debugging = false): MinInterpreter =
  var st:MinStack = newSeq[MinValue](0)
  var pr:MinParser
  var i:MinInterpreter = MinInterpreter(
    filename: "input", 
    pwd: "",
    parser: pr, 
    stack: st,
    scope: ROOT,
    debugging: debugging, 
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc copy(i: MinInterpreter, filename = "input"): MinInterpreter =
  result = newMinInterpreter(debugging = i.debugging)
  result.filename = filename
  result.pwd =  filename.parentDir
  result.stack = i.stack
  result.scope = i.scope
  result.currSym = MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")

proc error*(i: MinInterpreter, status: MinError, message = "") =
  var msg = if message == "": ERRORS[status] else: message
  if i.currSym.filename == "":
    stderr.writeLine("`$1`: Error - $2" % [i.currSym.symVal, msg])
  else:
    stderr.writeLine("$1 [$2,$3] `$4`: Error - $5" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, i.currSym.symVal, msg])
    quit(int(status))

proc open*(i: var MinInterpreter, stream:Stream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: var MinInterpreter) = 
  i.parser.close();

proc push*(i: var MinInterpreter, val: MinValue) = 
  i.debug val
  if val.kind == minSymbol:
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    let symbolProc = i.scope.getSymbol(symbol)
    if not symbolProc.isNil:
      #let filename = i.filename
      try:
        i.newDisposableScope("<" & symbol & ">"):
          #i.debug "SCOPE: " & i.scope.fullname
          symbolProc(i) 
      except:
        i.error(errSystem, getCurrentExceptionMsg())
      #finally:
      #  i.filename = filename # filename may change when evaluating quotations
    else:
      let sigilProc = i.scope.getSigil(sigil)
      if symbol.len > 1 and not sigilProc.isNil:
        let sym = symbol[1..symbol.len-1]
        #let filename = i.filename
        try:
          i.stack.add(MinValue(kind: minString, strVal: sym))
          sigilProc(i) 
        except:
          i.error(errSystem, getCurrentExceptionMsg())
        #finally:
        #  i.filename = filename # Filename may change when evaluating quotations
      else:
        i.error(errUndefined, "Undefined symbol: '"&val.symVal&"'")
        return
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
    var i2 = i.copy("eval")
    i2.open(newStringStream(s), "eval")
    discard i2.parser.getToken() 
    i2.interpret()
    i.stack = i2.stack
    i.scope = i2.scope
  except:
    stderr.writeLine getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc load*(i: var MinInterpreter, s: string) =
  let fn = i.filename
  try:
    var i2 = i.copy(s)
    i2.open(newStringStream(s.readFile), s)
    discard i2.parser.getToken() 
    i2.interpret()
    i.stack = i2.stack
    i.scope = i2.scope
  except:
    stderr.writeLine getCurrentExceptionMsg()
  finally:
    i.filename = fn

proc apply*(i: var MinInterpreter, symbol: string) =
  i.scope.getSymbol(symbol)(i)

proc copystack*(i: var MinInterpreter): MinStack =
  var s = newSeq[MinValue](0)
  for i in i.stack:
    s.add i
  return s

var INTERPRETER* = newMinInterpreter()
