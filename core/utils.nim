import 
  strutils, 
  critbits,
  json,
  terminal
import 
  ../packages/nim-sgregex/sgregex,
  parser, 
  value,
  scope,
  interpreter

# Library methods

proc define*(i: In): ref MinScope =
  var scope = new MinScope
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc): ref MinScope =
  scope.symbols[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)
  return scope

proc symbol*(scope: ref MinScope, sym: string, v: MinValue): ref MinScope =
  scope.symbols[sym] = MinOperator(val: v, kind: minValOp, sealed: true)
  return scope

proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc): ref MinScope =
  scope.sigils[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)
  return scope

proc sigil*(scope: ref MinScope, sym: string, v: MinValue): ref MinScope =
  scope.sigils[sym] = MinOperator(val: v, kind: minValOp, sealed: true)
  return scope

proc finalize*(scope: ref MinScope, name: string = "") =
  var mdl = newSeq[MinValue](0).newVal(nil)
  mdl.scope = scope
  let op = proc(i: In) {.gcsafe, closure.} =
    i.evaluating = true
    i.push mdl
    i.evaluating = false
  if name != "":
    scope.previous.symbols[name] = MinOperator(kind: minProcOp, prc: op)

# Dictionary Methods

proc dget*(q: MinValue, s: MinValue): MinValue =
  # Assumes q is a dictionary
  for v in q.qVal:
    if v.qVal[0].getString == s.getString:
      return v.qVal[1]
  raiseInvalid("Dictionary key '$1' not found" % s.getString)

proc dhas*(q: MinValue, s: MinValue): bool =
  # Assumes q is a dictionary
  for v in q.qVal:
    if v.qVal[0].getString == s.getString:
      return true
  return false

proc ddel*(i: In, p: MinValue, s: MinValue): MinValue {.discardable.} =
  # Assumes q is a dictionary
  var q = newVal(p.qVal, i.scope)
  var found = false
  var c = -1
  for v in q.qVal:
    c.inc
    if v.qVal[0].getString == s.getString:
      found = true
      break
  if found:
    q.qVal.delete(c)
  return q
      
proc dset*(i: In, p: MinValue, s: MinValue, m: MinValue): MinValue {.discardable.}=
  # Assumes q is a dictionary
  var q = newVal(p.qVal, i.scope)
  var found = false
  var c = -1
  for v in q.qVal:
    c.inc
    if v.qVal[0].getString == s.getString:
      found = true
      break
  if found:
    q.qVal.delete(c)
    q.qVal.insert(@[s.getString.newSym, m].newVal(i.scope), c)
  else:
    q.qVal.add(@[s.getString.newSym, m].newVal(i.scope))
  return q

proc keys*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  result = newSeq[MinValue](0).newVal(i.scope)
  for v in q.qVal:
    result.qVal.add v.qVal[0]

proc values*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  result = newSeq[MinValue](0).newVal(i.scope)
  for v in q.qVal:
    result.qVal.add v.qVal[1]

# JSON interop

proc `%`*(a: MinValue): JsonNode =
  case a.kind:
    of minBool:
      return %a.boolVal
    of minSymbol:
      return %(";sym:$1" % [a.symVal])
    of minString:
      return %a.strVal
    of minInt:
      return %a.intVal
    of minFloat:
      return %a.floatVal
    of minQuotation:
      if a.isDictionary:
        result = newJObject()
        for i in a.qVal:
          result[$i.qVal[0].symVal] = %i.qVal[1]
      else:
        result = newJArray()
        for i in a.qVal:
          result.add %i

proc fromJson*(i: In, json: JsonNode): MinValue = 
  case json.kind:
    of JNull:
      result = newSeq[MinValue](0).newVal(i.scope)
    of JBool: 
      result = json.getBVal.newVal
    of JInt:
      result = json.getNum.newVal
    of JFloat:
      result = json.getFNum.newVal
    of JString:
      let s = json.getStr
      if s.match("^;sym:"):
        result = sgregex.replace(s, "^;sym:", "").newSym
      else:
        result = json.getStr.newVal
    of JObject:
      var res = newSeq[MinValue](0)
      for key, value in json.pairs:
        res.add @[key.newSym, i.fromJson(value)].newVal(i.scope)
      return res.newVal(i.scope)
    of JArray:
      var res = newSeq[MinValue](0)
      for value in json.items:
        res.add i.fromJson(value)
      return res.newVal(i.scope)

# Validators

proc reqStackSize*(i: var MinInterpreter, n: int) = 
  if i.stack.len < n:
    raiseEmptyStack()

proc reqBool*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isBool:
    raiseInvalid("A bool value is required on the stack")

proc reqTwoBools*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isBool or not b.isBool:
    raiseInvalid("Two bool values are required on the stack")

proc reqInt*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isInt:
    raiseInvalid("An integer is required on the stack")

proc reqNumber*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isNumber:
    raiseInvalid("A number is required on the stack")

proc reqTwoInts*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isInt or not b.isInt:
    raiseInvalid("Two integers are required on the stack")

proc reqQuotation*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")

proc reqQuotationOfQuotations*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isQuotation:
      raiseInvalid("A quotation of quotations is required on the stack")

proc reqQuotationOfNumbers*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isNumber:
      raiseInvalid("A quotation of numbers is required on the stack")

proc reqIntAndQuotation*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isInt and b.isQuotation):
    raiseInvalid("An integer and a quotation are required on the stack")

proc reqTwoNumbers*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isNumber and b.isNumber):
    raiseInvalid("Two numbers are required on the stack")

proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isString and b.isString or a.isNumber and b.isNumber):
    raiseInvalid("Two numbers or two strings are required on the stack")

proc reqIntAndString*(i: var MinInterpreter, b, a: var MinValue) =
  b = i.pop
  a = i.pop
  if not (a.isString and b.isInt):
    raiseInvalid("A string and a number are required on the stack")

proc reqString*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isString:
    raiseInvalid("A string is required on the stack")

proc reqStringLikeAndQuotation*(i: var MinInterpreter, a, q: var MinValue) =
  a = i.pop
  q = i.pop
  if not a.isStringLike or not q.isQuotation:
    raiseInvalid("A string or symbol and a quotation are required on the stack")

proc reqQuotationAndString*(i: var MinInterpreter, q, a: var MinValue) =
  q = i.pop
  a = i.pop
  if not a.isString or not q.isQuotation:
    raiseInvalid("A string and a quotation are required on the stack")

proc reqQuotationAndStringLike*(i: var MinInterpreter, q, a: var MinValue) =
  q = i.pop
  a = i.pop
  if not a.isStringLike or not q.isQuotation:
    raiseInvalid("A quotation and a string or a symbol are required on the stack")

proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation and not a.isString:
    raiseInvalid("A quotation or a string is required on the stack")

proc reqStringLike*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isStringLike:
    raiseInvalid("A quoted symbol or a string is required on the stack")

proc reqTwoStrings*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isString or not b.isString:
    raiseInvalid("Two strings are required on the stack")

proc reqTwoStringLike*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isStringLike or not b.isStringLike:
    raiseInvalid("Two symbols or strings are required on the stack")

proc reqThreeStrings*(i: var MinInterpreter, a, b, c: var MinValue) =
  a = i.pop
  b = i.pop
  c = i.pop
  if not a.isString or not b.isString or not c.isString: 
    raiseInvalid("Three strings are required on the stack")

proc reqTwoQuotations*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isQuotation or not b.isQuotation:
    raiseInvalid("Two quotations are required on the stack")

proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isQuotation and b.isQuotation or a.isString and b.isString):
    raiseInvalid("Two quotations or two strings are required on the stack")

proc reqThreeQuotations*(i: var MinInterpreter, a, b, c: var MinValue) =
  a = i.pop
  b = i.pop
  c = i.pop
  if not a.isQuotation or not b.isQuotation or not c.isQuotation: 
    raiseInvalid("Three quotations are required on the stack")

proc reqFourQuotations*(i: var MinInterpreter, a, b, c, d: var MinValue) =
  a = i.pop
  b = i.pop
  c = i.pop
  d = i.pop
  if not a.isQuotation or not b.isQuotation or not c.isQuotation or not d.isQuotation:
    raiseInvalid("Four quotations are required on the stack")

proc reqTwoSimilarTypesNonSymbol*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not ((a.kind == a.kind or (a.isNumber and a.isNumber)) and not a.isSymbol):
    raiseInvalid("Two non-symbol values of similar type are required on the stack")

proc reqDictionary*(i: In, q: var MinValue) =
  q = i.pop
  if not q.isDictionary:
    raiseInvalid("An dictionary is required on the stack")
