import 
  streams, 
  strutils, 
  critbits, 
  os,
  oids,
  algorithm,
  logging
import 
  value,
  scope,
  parser

type
  MinTrappedException* = ref object of SystemError
  MinRuntimeError* = ref object of SystemError
    qVal*: seq[MinValue]

proc raiseRuntime*(msg: string, qVal: var seq[MinValue]) =
  raise MinRuntimeError(msg: msg, qVal: qVal)

proc dump*(i: MinInterpreter): string =
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug*(i: In, value: MinValue) =
  debug("{" & i.dump & $value & "}")

proc debug*(i: In, value: string) =
  debug(value)

template withScope*(i: In, q: MinValue, res:ref MinScope, body: untyped): untyped =
  let origScope = i.scope
  i.scope = q.scope.copy
  i.scope.parent = origScope
  body
  res = i.scope
  i.scope = origScope

template withScope*(i: In, q: MinValue, body: untyped): untyped =
  var scope = newScopeRef(i.scope, "with")
  i.withScope(q, scope):
    body

proc newMinInterpreter*(filename = "input", pwd = ""): MinInterpreter =
  var stack:MinStack = newSeq[MinValue](0)
  var trace:MinStack = newSeq[MinValue](0)
  var stackcopy:MinStack = newSeq[MinValue](0)
  var pr:MinParser
  var scope = new MinScope
  scope.name = "ROOT"
  var i:MinInterpreter = MinInterpreter(
    filename: filename, 
    pwd: pwd,
    parser: pr, 
    stack: stack,
    trace: trace,
    stackcopy: stackcopy,
    scope: scope,
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc copy*(i: MinInterpreter, filename: string): MinInterpreter =
  result = newMinInterpreter()
  result.filename = filename
  result.pwd =  filename.parentDir
  result.stack = i.stack
  result.trace = i.trace
  result.stackcopy = i.stackcopy
  result.scope = i.scope
  result.currSym = MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")

proc formatError(sym: MinValue, message: string): string =
  if sym.filename.isNil or sym.filename == "":
    return "[$1]: $2" % [sym.symVal, message]
  else:
    return "$1($2,$3) [$4]: $5" % [sym.filename, $sym.line, $sym.column, sym.symVal, message]

proc formatTrace(sym: MinValue): string =
  if sym.filename.isNil or sym.filename == "":
    return "  <native> in symbol: $1" % [sym.symVal]
  else:
    return "  $1($2,$3) in symbol: $4" % [sym.filename, $sym.line, $sym.column, sym.symVal]

proc stackTrace(i: In) =
  var trace = i.trace
  trace.reverse()
  for sym in trace:
    notice sym.formatTrace

proc error(i: In, message: string) =
  error(i.currSym.formatError(message))

proc open*(i: In, stream:Stream, filename: string) =
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: In) = 
  i.parser.close();

proc push*(i: In, val: MinValue) {.gcsafe.}

proc apply*(i: In, op: MinOperator, s: var ref MinScope, name="apply") =
  case op.kind
  of minProcOp:
    op.prc(i)
  of minValOp:
    if op.val.kind == minQuotation:
      var q = op.val
      i.withScope(q, s):
        for e in q.qVal:
          i.push e
    else:
      i.push(op.val)

proc apply*(i: In, op: MinOperator, name="apply") =
  var scope = newScopeRef(i.scope, name)
  i.apply(op, scope)

proc push*(i: In, val: MinValue) = 
  if val.kind == minSymbol:
    i.debug(val)
    i.trace.add val
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    let sigil = "" & symbol[0]
    let found = i.scope.hasSymbol(symbol)
    if found:
      let sym = i.scope.getSymbol(symbol) 
      i.apply(sym)
    else:
      let found = i.scope.hasSigil(sigil)
      if symbol.len > 1 and found:
        let sig = i.scope.getSigil(sigil) 
        let sym = symbol[1..symbol.len-1]
        i.stack.add(MinValue(kind: minString, strVal: sym))
        i.apply(sig)
      else:
        raiseUndefined("Undefined symbol '$1' in scope '$2'" % [val.symVal, i.scope.fullname])
    discard i.trace.pop
  else:
    i.stack.add(val)

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

proc interpret*(i: In): MinValue {.gcsafe, discardable.} =
  var val: MinValue
  while i.parser.token != tkEof: 
    if i.trace.len == 0:
      i.stackcopy = i.stack
    try:
      val = i.parser.parseMinValue(i)
      i.push val
    except MinRuntimeError:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      error("$1:$2,$3 $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, msg])
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
  if i.stack.len > 0:
    return i.stack[i.stack.len - 1]

proc unquote*(i: In, name: string, q: var MinValue, scope: var ref MinScope) =
  i.withScope(q, scope): 
    for v in q.qVal:
      i.push v

proc unquote*(i: In, name: string, q: var MinValue) =
  var scope = newScopeRef(i.scope, "unquote")
  i.unquote(name, q, scope)

proc eval*(i: In, s: string, name="<eval>") =
  var i2 = i.copy(name)
  i2.open(newStringStream(s), name)
  discard i2.parser.getToken() 
  i2.interpret()
  i.trace = i2.trace
  i.stackcopy = i2.stackcopy
  i.stack = i2.stack
  i.scope = i2.scope

proc load*(i: In, s: string) =
  var i2 = i.copy(s)
  i2.open(newStringStream(s.readFile), s)
  discard i2.parser.getToken() 
  i2.interpret()
  i.trace = i2.trace
  i.stackcopy = i2.stackcopy
  i.stack = i2.stack
  i.scope = i2.scope