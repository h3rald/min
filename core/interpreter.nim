import streams, strutils, critbits, os
import 
  types, 
  parser,
  ../vendor/linenoise

var ROOT*: ref MinScope = new MinScope

ROOT.name = "ROOT"


proc raiseUndefined(msg: string) =
  raise MinUndefinedError(msg: msg)

proc raiseEmptyStack() =
  raise MinEmptyStackError(msg:"Insufficient items on the stack")

proc fullname*(scope: ref MinScope): string =
  result = scope.name
  if scope.parent.isNotNil:
    result = scope.parent.fullname & ":" & result

proc getSymbol*(scope: ref MinScope, key: string): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif scope.parent.isNotNil:
    return scope.parent.getSymbol(key)

proc delSymbol*(scope: ref MinScope, key: string): bool {.discardable.}=
  if scope.symbols.hasKey(key):
    scope.symbols.excl(key)
    return true
  return false

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator): bool {.discardable.}=
  result = false
  # check if a symbol already exists in current scope
  if scope.isNotNil and scope.symbols.hasKey(key):
    scope.symbols[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the symbol
    if scope.parent.isNotNil:
      result = scope.parent.setSymbol(key, value)

proc getSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif scope.parent.isNotNil:
    return scope.parent.getSigil(key)

proc dump*(i: MinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug*(i: In, value: MinValue) =
  if i.debugging: 
    stderr.writeLine("-- " & i.dump & $value)

proc debug*(i: In, value: string) =
  if i.debugging: 
    stderr.writeLine("-- " & value)

proc newScope*(i: In, id: string, q: var MinValue) =
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope

template createScope*(i: In, id: string, q: MinValue, body: stmt): stmt {.immediate.} =
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope
  #i.debug "[scope] " & q.scope.fullname
  let scope = i.scope
  i.scope = q.scope
  body
  #i.debug "[scope] " & scope.fullname
  i.scope = scope

template withScope*(i: In, q: MinValue, body: stmt): stmt {.immediate.} =
  #i.debug "[scope] " & q.scope.fullname
  let origScope = i.scope
  i.scope = q.scope
  body
  #i.debug "[scope] " & scope.fullname
  i.scope = origScope

proc copystack*(i: MinInterpreter): MinStack =
  var s = newSeq[MinValue](0)
  for i in i.stack:
    s.add i
  return s

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
    unsafe: false,
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc copy*(i: MinInterpreter, filename: string): MinInterpreter =
  result = newMinInterpreter(debugging = i.debugging)
  result.filename = filename
  result.pwd =  filename.parentDir
  result.stack = i.copystack
  result.scope = i.scope
  result.currSym = MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")

proc error(i: MinInterpreter, message: string) =
  if i.currSym.filename == "":
    stderr.writeLine("`$1`: Error - $2" % [i.currSym.symVal, message])
  else:
    stderr.writeLine("$1 [$2,$3] `$4`: Error - $5" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, i.currSym.symVal, message])
    quit(100)

template execute(i: In, body: stmt) {.immediate.}=
  let stack = i.copystack
  try:
    body
  except MinRuntimeError:
    i.stack = stack
    stderr.writeLine("$1 [$2,$3]: $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, getCurrentExceptionMsg()])
  except:
    i.stack = stack
    i.error(getCurrentExceptionMsg())

proc open*(i: In, stream:Stream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: In) = 
  i.parser.close();

proc push*(i: In, val: MinValue) = 
  i.debug val
  if val.kind == minSymbol:
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    let symbolProc = i.scope.getSymbol(symbol)
    if symbolProc.isNotNil:
      if i.unsafe:
        let stack = i.copystack
        try:
          symbolProc(i) 
        except:
          i.stack = stack
          raise
      else:
        i.execute:
          i.symbolProc
    else:
      let sigilProc = i.scope.getSigil(sigil)
      if symbol.len > 1 and sigilProc.isNotNil:
        let sym = symbol[1..symbol.len-1]
        i.stack.add(MinValue(kind: minString, strVal: sym))
        if i.unsafe:
          let stack = i.copystack
          try:
            sigilProc(i) 
          except:
            i.stack = stack
            raise
        else:
          i.execute:
            i.sigilProc
      else:
        raiseUndefined("Undefined symbol: '"&val.symVal&"'")
  else:
    i.stack.add(val)

proc push*(i: In, q: seq[MinValue]) =
  for e in q:
    i.push e

proc pop*(i: In): MinValue =
  if i.stack.len > 0:
    return i.stack.pop
  else:
    raiseEmptyStack()

proc peek*(i: MinInterpreter): MinValue = 
  if i.stack.len > 0:
    return i.stack[i.stack.len-1]
  else:
    raiseEmptyStack()

proc interpret*(i: In) = 
  var val: MinValue
  while i.parser.token != tkEof: 
    i.execute:
      val = i.parser.parseMinValue
    i.push val

proc unquote*(i: In, name: string, q: var MinValue) =
  i.createScope(name, q): 
    for v in q.qVal:
      i.push v

proc eval*(i: In, s: string) =
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

proc load*(i: In, s: string) =
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

proc apply*(i: In, symbol: string) =
  i.scope.getSymbol(symbol)(i)

var INTERPRETER* = newMinInterpreter()
