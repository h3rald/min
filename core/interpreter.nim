import 
  streams, 
  strutils, 
  critbits, 
  os,
  oids,
  algorithm
import 
  value,
  parser

type
  MinTrappedException* = ref object of SystemError
  MinRuntimeError* = ref object of SystemError
    qVal*: seq[MinValue]

proc raiseRuntime*(msg: string, qVal: var seq[MinValue]) =
  raise MinRuntimeError(msg: msg, qVal: qVal)

proc fullname*(scope: ref MinScope): string =
  result = scope.name
  if not scope.parent.isNil:
    result = scope.parent.fullname & ":" & result

proc getSymbol*(scope: ref MinScope, key: string): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif not scope.parent.isNil:
    return scope.parent.getSymbol(key)
  else:
    raiseUndefined("Symbol '$1' not found." % key)

proc hasSymbol*(scope: ref MinScope, key: string): bool =
  if scope.symbols.hasKey(key):
    return true
  elif not scope.parent.isNil:
    return scope.parent.hasSymbol(key)
  else:
    return false

proc delSymbol*(scope: ref MinScope, key: string): bool {.discardable.}=
  if scope.symbols.hasKey(key):
    if scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key) 
    scope.symbols.excl(key)
    return true
  return false

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator): bool {.discardable.}=
  result = false
  # check if a symbol already exists in current scope
  if not scope.isNil and scope.symbols.hasKey(key):
    if scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key) 
    scope.symbols[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the symbol
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value)

proc getSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif not scope.parent.isNil:
    return scope.parent.getSigil(key)
  else:
    raiseUndefined("Sigil '$1' not found." % key)

proc hasSigil*(scope: ref MinScope, key: string): bool =
  if scope.sigils.hasKey(key):
    return true
  elif not scope.parent.isNil:
    return scope.parent.hasSigil(key)
  else:
    return false

proc dump*(i: MinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug*(i: In, value: MinValue) =
  if i.debugging: 
    echo $value
    stderr.writeLine("-- " & i.dump & $value)

proc debug*(i: In, value: string) =
  if i.debugging: 
    stderr.writeLine("-- " & value)

proc newScope*(i: In, id: string, q: var MinValue) =
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope

template createScope*(i: In, id: string, q: MinValue, body: untyped): untyped =
  q.scope = new MinScope
  q.scope.name = id
  q.scope.parent = i.scope
  let scope = i.scope
  i.scope = q.scope
  body
  i.scope = scope

template withScope*(i: In, q: MinValue, body: untyped): untyped =
  #i.debug "[scope] " & q.scope.fullname
  let origScope = i.scope
  i.scope = q.scope
  body
  #i.debug "[scope] " & scope.fullname
  i.scope = origScope

template addScope*(i: In, id: string, q: MinValue, body: untyped): untyped =
  var added = new MinScope
  added.name = id
  if q.scope.isNil:
    q.scope = i.scope
  added.parent = q.scope
  let scope = i.scope
  i.scope = added
  body
  i.scope = scope

proc newMinInterpreter*(debugging = false): MinInterpreter =
  var stack:MinStack = newSeq[MinValue](0)
  var trace:MinStack = newSeq[MinValue](0)
  var stackcopy:MinStack = newSeq[MinValue](0)
  var pr:MinParser
  var scope = new MinScope
  scope.name = "ROOT"
  var i:MinInterpreter = MinInterpreter(
    filename: "input", 
    pwd: "",
    parser: pr, 
    stack: stack,
    trace: trace,
    stackcopy: stackcopy,
    scope: scope,
    debugging: debugging, 
    unsafe: false,
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc copy*(i: MinInterpreter, filename: string): MinInterpreter =
  result = newMinInterpreter(debugging = i.debugging)
  result.filename = filename
  result.pwd =  filename.parentDir
  result.stack = i.stack
  result.trace = i.trace
  result.stackcopy = i.stackcopy
  result.scope = i.scope
  result.currSym = MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")

proc formatError(sym: MinValue, message: string): string =
  if sym.filename.isNil or sym.filename == "":
    return "(!) `$1`: $2" % [sym.symVal, message]
  else:
    return "(!) $1($2,$3) `$4`: $5" % [sym.filename, $sym.line, $sym.column, sym.symVal, message]

proc formatTrace(sym: MinValue): string =
  if sym.filename.isNil or sym.filename == "":
    return "    - [native] in symbol: $1" % [sym.symVal]
  else:
    return "    - $1($2,$3) in symbol: $4" % [sym.filename, $sym.line, $sym.column, sym.symVal]

proc stackTrace(i: In) =
  var trace = i.trace
  trace.reverse()
  for sym in trace:
    stderr.writeLine sym.formatTrace

proc error(i: In, message: string) =
  stderr.writeLine i.currSym.formatError(message)

#template execute(i: In, body: untyped) =

proc open*(i: In, stream:Stream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: In) = 
  i.parser.close();

proc push*(i: In, val: MinValue) {.gcsafe.}

proc apply*(i: In, op: MinOperator, name="apply") =
  case op.kind
  of minProcOp:
    op.prc(i)
  of minValOp:
    if op.val.kind == minQuotation:
      var q = op.val
      i.addScope(name & "#" & $genOid(), q):
        #echo "a1: ", i.scope.fullname
        for e in q.qVal:
          i.push e
    else:
      i.push(op.val)

proc push*(i: In, val: MinValue) = 
  i.debug val
  if val.kind == minSymbol:
    i.trace.add val
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    let found = i.scope.hasSymbol(symbol)
    if found:
      let sym = i.scope.getSymbol(symbol) 
      if i.unsafe:
        i.apply(sym)
      #if i.unsafe:
        #let stack = i.stack
        #try:
        #  i.apply(sym) 
        #except:
        #  echo "yeah!"
        #  i.stack = stack
        #  raise
      else:
        #i.execute:
        i.apply(sym)
    else:
      let found = i.scope.hasSigil(sigil)
      if symbol.len > 1 and found:
        let sig = i.scope.getSigil(sigil) 
        let sym = symbol[1..symbol.len-1]
        i.stack.add(MinValue(kind: minString, strVal: sym))
        #if i.unsafe:
          #let stack = i.stack
          #try:
          #  i.apply(sig)
          #except:
          #  echo "yup!"
          #  i.stack = stack
          #  raise
        #else:
          #i.execute:
        i.apply(sig)
      else:
        raiseUndefined("Undefined symbol '$1' in scope '$2'" % [val.symVal, i.scope.fullname])
    discard i.trace.pop
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

proc interpret*(i: In) {.gcsafe.}= 
  var val: MinValue
  while i.parser.token != tkEof: 
    if i.trace.len == 0:
      i.stackcopy = i.stack
    try:
      val = i.parser.parseMinValue
      i.push val
    except MinRuntimeError:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      stderr.writeLine("(!) $1:$2,$3 $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, msg])
      i.stackTrace
      raise MinTrappedException(msg: msg)
    except MinTrappedException:
      raise
    except:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      i.error(msg)
      i.stackTrace
      raise MinTrappedException(msg: msg)

proc unquote*(i: In, name: string, q: var MinValue) =
  i.createScope(name, q): 
    for v in q.qVal:
      i.push v

proc eval*(i: In, s: string, name="<eval>") =
  #let fn = i.filename
  #try:
    var i2 = i.copy(name)
    i2.open(newStringStream(s), name)
    discard i2.parser.getToken() 
    i2.interpret()
    i.trace = i2.trace
    i.stackcopy = i2.stackcopy
    i.stack = i2.stack
    i.scope = i2.scope
  #except:
  #  stderr.writeLine getCurrentExceptionMsg()
  #  raise
  #finally:
  #  i.filename = fn

proc load*(i: In, s: string) =
  #let fn = i.filename
  #try:
    var i2 = i.copy(s)
    i2.open(newStringStream(s.readFile), s)
    discard i2.parser.getToken() 
    i2.interpret()
    i.trace = i2.trace
    i.stackcopy = i2.stackcopy
    i.stack = i2.stack
    i.scope = i2.scope
  #except:
  #  stderr.writeLine getCurrentExceptionMsg()
  #  raise
  #finally:
  #  i.filename = fn
