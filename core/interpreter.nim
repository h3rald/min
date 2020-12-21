import 
  streams, 
  strutils, 
  sequtils,
  critbits,
  algorithm
when defined(mini):
  import
    minilogger
else:
  import 
    os,
    logging
import 
  baseutils,
  value,
  scope,
  parser

type
  MinTrappedException* = ref object of CatchableError
  MinRuntimeError* = ref object of CatchableError
    data*: MinValue

var COMPILEDMINFILES* {.threadvar.}: CritBitTree[MinOperatorProc]
var COMPILEDASSETS* {.threadvar.}: CritBitTree[MinOperatorProc]

const USER_SYMBOL_REGEX* = "^[a-zA-Z_][a-zA-Z0-9/!?+*._-]*$"

proc raiseRuntime*(msg: string, data: MinValue) {.extern:"min_exported_symbol_$1".}=
  data.objType = "error"
  raise MinRuntimeError(msg: msg, data: data)

proc dump*(i: MinInterpreter): string {.extern:"min_exported_symbol_$1".}=
  var s = ""
  for item in i.stack:
    s = s & $item & " "
  return s

proc debug*(i: In, value: MinValue) {.extern:"min_exported_symbol_$1".}=
  debug("(" & i.dump & $value & ")")

proc debug*(i: In, value: string) {.extern:"min_exported_symbol_$1_2".}=
  debug(value)

template withScope*(i: In, res:ref MinScope, body: untyped): untyped =
  let origScope = i.scope
  try:
    i.scope = newScopeRef(origScope)
    body
    res = i.scope
  finally:
    i.scope = origScope

template withScope*(i: In, body: untyped): untyped =
  let origScope = i.scope
  try:
    i.scope = newScopeRef(origScope)
    body
  finally:
    i.scope = origScope

template withDictScope*(i: In, s: ref MinScope, body: untyped): untyped =
  let origScope = i.scope
  try:
    i.scope = s
    body
  finally:
    i.scope = origScope

proc newMinInterpreter*(filename = "input", pwd = ""): MinInterpreter {.extern:"min_exported_symbol_$1".}=
  var path = pwd
  when not defined(mini): 
    if not pwd.isAbsolute:
      path = joinPath(getCurrentDir(), pwd)
  var stack:MinStack = newSeq[MinValue](0)
  var trace:MinStack = newSeq[MinValue](0)
  var stackcopy:MinStack = newSeq[MinValue](0)
  var pr:MinParser
  var scope = newScopeRef(nil)
  var i:MinInterpreter = MinInterpreter(
    filename: filename, 
    pwd: path,
    parser: pr, 
    stack: stack,
    trace: trace,
    stackcopy: stackcopy,
    scope: scope,
    currSym: MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")
  )
  return i

proc copy*(i: MinInterpreter, filename: string): MinInterpreter {.extern:"min_exported_symbol_$1_2".}=
  var path = filename
  when not defined(mini): 
    if not filename.isAbsolute:
      path = joinPath(getCurrentDir(), filename)
  result = newMinInterpreter()
  result.filename = filename
  result.pwd =  path.parentDirEx
  result.stack = i.stack
  result.trace = i.trace
  result.stackcopy = i.stackcopy
  result.scope = i.scope
  result.currSym = MinValue(column: 1, line: 1, kind: minSymbol, symVal: "")

proc formatError(sym: MinValue, message: string): string {.extern:"min_exported_symbol_$1".}=
  if sym.filename == "":
    return "[$1]: $2" % [sym.symVal, message]
  else:
    return "$1($2,$3) [$4]: $5" % [sym.filename, $sym.line, $sym.column, sym.symVal, message]

proc formatTrace(sym: MinValue): string {.extern:"min_exported_symbol_$1".}=
  if sym.filename == "":
    return "<native> in symbol: $1" % [sym.symVal]
  else:
    return "$1($2,$3) in symbol: $4" % [sym.filename, $sym.line, $sym.column, sym.symVal]

proc stackTrace*(i: In) =
  var trace = i.trace
  trace.reverse()
  for sym in trace:
    notice sym.formatTrace

proc error(i: In, message: string) =
  error(i.currSym.formatError(message))

proc open*(i: In, stream:Stream, filename: string) {.extern:"min_exported_symbol_$1_2".}=
  i.filename = filename
  i.parser.open(stream, filename)

proc close*(i: In) {.extern:"min_exported_symbol_$1_2".}= 
  i.parser.close();

proc push*(i: In, val: MinValue) {.gcsafe, extern:"min_exported_symbol_$1".} 

proc call*(i: In, q: var MinValue): MinValue {.gcsafe, extern:"min_exported_symbol_$1".}=
  var i2 = newMinInterpreter("<call>")
  i2.trace = i.trace
  i2.scope = i.scope
  try:
    i2.withScope(): 
      for v in q.qVal:
        i2.push v
  except:
    i.currSym = i2.currSym
    i.trace = i2.trace
    raise
  return i2.stack.newVal

proc callValue*(i: In, v: var MinValue): MinValue {.gcsafe, extern:"min_exported_symbol_$1".}=
  var i2 = newMinInterpreter("<call-value>")
  i2.trace = i.trace
  i2.scope = i.scope
  try:
    i2.withScope(): 
      i2.push v
  except:
    i.currSym = i2.currSym
    i.trace = i2.trace
    raise
  return i2.stack[0]

proc copyDict*(i: In, val: MinValue): MinValue {.gcsafe, extern:"min_exported_symbol_$1".}=
   # Assuming val is a dictionary
   var v = newDict(i.scope)
   for item in val.scope.symbols.pairs:
     v.scope.symbols[item.key] = item.val
   for item in val.scope.sigils.pairs:
     v.scope.sigils[item.key] = item.val
   if val.objType != "":
     v.objType = val.objType
   if not val.obj.isNil:
     v.obj = val.obj
   return v

proc applyDict*(i: In, val: MinValue): MinValue {.gcsafe, extern:"min_exported_symbol_$1".}=
   # Assuming val is a dictionary
   var v = i.copyDict(val)
   for item in v.dVal.pairs:
     var value = item.val.val
     v.scope.symbols[item.key] = MinOperator(kind: minValOp, val: i.callValue(value), sealed: false)
   return v

proc apply*(i: In, op: MinOperator) {.gcsafe, extern:"min_exported_symbol_$1".}=
  if op.kind == minProcOp:
    op.prc(i)
  else:
    if op.val.kind == minQuotation:
      var newscope = newScopeRef(i.scope)
      i.withScope(newscope):
        for e in op.val.qVal:
          i.push e
    else:
      i.push(op.val)

proc dequote*(i: In, q: var MinValue) {.extern:"min_exported_symbol_$1".}=
  if q.kind == minQuotation:
    i.withScope(): 
      let qqval = deepCopy(q.qVal)
      for v in q.qVal:
        i.push v
      q.qVal = qqval
  else:
    i.push(q)

proc apply*(i: In, q: var MinValue) {.gcsafe, extern:"min_exported_symbol_$1_2".}=
  var i2 = newMinInterpreter("<apply>")
  i2.trace = i.trace
  i2.scope = i.scope
  try:
    i2.withScope(): 
      for v in q.qVal:
        if (v.kind == minQuotation):
          var v2 = v
          i2.dequote(v2)
        else:
          i2.push v
  except:
    i.currSym = i2.currSym
    i.trace = i2.trace
    raise
  i.push i2.stack.newVal

proc push*(i: In, val: MinValue) {.gcsafe, extern:"min_exported_symbol_$1".}= 
  if val.kind == minSymbol:
    i.debug(val)
    i.trace.add val
    if not i.evaluating:
      i.currSym = val
    let symbol = val.symVal
    if i.scope.hasSymbol(symbol):
      i.apply i.scope.getSymbol(symbol) 
    else: 
      var qIndex = symbol.find('"')
      if qIndex > 0:
        let sigil = symbol[0..qIndex-1]
        if not i.scope.hasSigil(sigil):
          raiseUndefined("Undefined sigil '$1'"%sigil)
        i.stack.add(MinValue(kind: minString, strVal: symbol[qIndex+1..symbol.len-2]))
        i.apply(i.scope.getSigil(sigil))
      else:
        let sigil = "" & symbol[0]
        if symbol.len > 1 and i.scope.hasSigil(sigil):
          i.stack.add(MinValue(kind: minString, strVal: symbol[1..symbol.len-1]))
          i.apply(i.scope.getSigil(sigil))
        else:
          raiseUndefined("Undefined symbol '$1'" % [val.symVal])
    discard i.trace.pop
  elif val.kind == minDictionary and val.objType != "module":
    # Dictionary must be copied every time they are interpreted, otherwise when they are used in cycles they reference each other.
    var v = i.copyDict(val)
    i.stack.add(v)
  else:
    i.stack.add(val)

proc pop*(i: In): MinValue {.extern:"min_exported_symbol_$1".}=
  if i.stack.len > 0:
    return i.stack.pop
  else:
    raiseEmptyStack()

proc peek*(i: MinInterpreter): MinValue {.extern:"min_exported_symbol_$1".}= 
  if i.stack.len > 0:
    return i.stack[i.stack.len-1]
  else:
    raiseEmptyStack()

template handleErrors*(i: In, body: untyped) =
  try:
    body
  except MinRuntimeError:
    let msg = getCurrentExceptionMsg()
    i.stack = i.stackcopy
    error("$1:$2,$3 $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, msg])
    i.stackTrace()
    i.trace = @[]
    raise MinTrappedException(msg: msg)
  except MinTrappedException:
    raise
  except:
    let msg = getCurrentExceptionMsg()
    i.stack = i.stackcopy
    i.error(msg)
    i.stackTrace()
    i.trace = @[]
    raise MinTrappedException(msg: msg)


proc interpret*(i: In, parseOnly=false): MinValue {.discardable, extern:"min_exported_symbol_$1".} =
  var val: MinValue
  var q: MinValue
  if parseOnly:
    q = newSeq[MinValue](0).newVal
  while i.parser.token != tkEof: 
    if i.trace.len == 0:
      i.stackcopy = i.stack
    try:
      val = i.parser.parseMinValue(i)
      if parseOnly:
        q.qVal.add val
      else:
        i.push val
    except MinRuntimeError:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      error("$1:$2,$3 $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, msg])
      i.stackTrace
      i.trace = @[]
      raise MinTrappedException(msg: msg)
    except MinTrappedException:
      raise
    except:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      i.error(msg)
      i.stackTrace
      i.trace = @[]
      raise MinTrappedException(msg: msg)
  if parseOnly:
    return q
  if i.stack.len > 0:
    return i.stack[i.stack.len - 1]

proc rawCompile*(i: In, indent = ""): seq[string] {.discardable, extern:"min_exported_symbol_$1".} =
  while i.parser.token != tkEof: 
    if i.trace.len == 0:
      i.stackcopy = i.stack
    try:
      result.add i.parser.compileMinValue(i, push = true, indent)
    except MinRuntimeError:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      error("$1:$2,$3 $4" % [i.currSym.filename, $i.currSym.line, $i.currSym.column, msg])
      i.stackTrace
      i.trace = @[]
      raise MinTrappedException(msg: msg)
    except MinTrappedException:
      raise
    except:
      let msg = getCurrentExceptionMsg()
      i.stack = i.stackcopy
      i.error(msg)
      i.stackTrace
      i.trace = @[]
      raise MinTrappedException(msg: msg)
    
proc compileFile*(i: In, main: bool): seq[string] {.discardable, extern:"min_exported_symbol_$1".} =
  result = newSeq[string](0)
  if not main:
    result.add "COMPILEDMINFILES[\"$#\"] = proc(i: In) {.gcsafe.}=" % i.filename
    result = result.concat(i.rawCompile("  "))
  else:
    result = i.rawCompile("")

proc initCompiledFile*(i: In, files: seq[string]): seq[string] {.discardable, extern:"min_exported_symbol_$1".} =
  result = newSeq[string](0)
  result.add "import min"
  if files.len > 0:
    result.add "import critbits"
  result.add "MINCOMPILED = true"
  result.add "var i = newMinInterpreter(\"$#\")" % i.filename
  result.add "i.stdLib()"

proc eval*(i: In, s: string, name="<eval>", parseOnly=false): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  var i2 = i.copy(name)
  i2.open(newStringStream(s), name)
  discard i2.parser.getToken() 
  result = i2.interpret(parseOnly)
  i.trace = i2.trace
  i.stackcopy = i2.stackcopy
  i.stack = i2.stack
  i.scope = i2.scope

proc load*(i: In, s: string, parseOnly=false): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  var fileLines = newSeq[string](0)
  var contents = ""
  try:
    fileLines = s.readFile().splitLines()
  except:
    fatal("Cannot read from file: " & s)
  if fileLines[0].len >= 2 and fileLines[0][0..1] == "#!":
    contents = ";;\n" & fileLines[1..fileLines.len-1].join("\n")
  else:
    contents = fileLines.join("\n")
  var i2 = i.copy(s)
  i2.open(newStringStream(contents), s)
  discard i2.parser.getToken() 
  result = i2.interpret(parseOnly)
  i.trace = i2.trace
  i.stackcopy = i2.stackcopy
  i.stack = i2.stack
  i.scope = i2.scope

proc require*(i: In, s: string, parseOnly=false): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  var fileLines = newSeq[string](0)
  var contents = ""
  try:
    fileLines = s.readFile().splitLines()
  except:
    fatal("Cannot read from file: " & s)
  if fileLines[0].len >= 2 and fileLines[0][0..1] == "#!":
    contents = ";;\n" & fileLines[1..fileLines.len-1].join("\n")
  else:
    contents = fileLines.join("\n")
  var i2 = i.copy(s)
  i2.open(newStringStream(contents), s)
  discard i2.parser.getToken() 
  discard i2.interpret(parseOnly)
  result = newDict(i2.scope)
  result.objType = "module"
  for key, value in i2.scope.symbols.pairs:
    result.scope.symbols[key] = value

proc parse*(i: In, s: string, name="<parse>"): MinValue {.extern:"min_exported_symbol_$1".}=
  return i.eval(s, name, true)

proc read*(i: In, s: string): MinValue {.extern:"min_exported_symbol_$1".}=
  return i.load(s, true)

