import 
  strutils, 
  sequtils,
  critbits,
  json,
  terminal
import 
  ../packages/nim-sgregex/sgregex,
  parser, 
  value,
  scope,
  interpreter

proc reverse[T](xs: openarray[T]): seq[T] =
  result = newSeq[T](xs.len)
  for i, x in xs:
    result[^i-1] = x 

# Library methods

proc define*(i: In): ref MinScope =
  var scope = new MinScope
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) =
  scope.symbols[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc symbol*(scope: ref MinScope, sym: string, v: MinValue) =
  scope.symbols[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) =
  scope.sigils[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, v: MinValue) =
  scope.sigils[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

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
    result.qVal.add v.qVal[0].getString.newVal

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

proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] =
  let stack = elements.join(" ")
  var valid = newSeq[string](0)
  result = newSeq[MinValue](0)
  let message = proc(invalid: string): string =
    result = "Incorrect values found on the stack:\n"
    result &= "- expected: {top} " & stack & " {bottom}\n"
    result &= "- got:      {top} " & valid.reverse.join(" ") & " " & invalid & " {bottom}"
  for element in elements:
    let value = i.pop
    result.add value
    case element:
      of "bool":
        if not value.isBool:
          raiseInvalid(message(value.typeName))
      of "int":
        if not value.isInt:
          raiseInvalid(message(value.typeName))
      of "num":
        if not value.isNumber:
          raiseInvalid(message(value.typeName))
      of "quot":
        if not value.isQuotation:
          raiseInvalid(message(value.typeName))
      of "dict":
        if not value.isDictionary:
          raiseInvalid(message(value.typeName))
      of "'sym":
        if not value.isStringLike:
          raiseInvalid(message(value.typeName))
      of "sym":
        if not value.isSymbol:
          raiseInvalid(message(value.typeName))
      of "float":
        if not value.isFloat:
          raiseInvalid(message(value.typeName))
      of "string":
        if not value.isString:
          raiseInvalid(message(value.typeName))
      of "a":
        discard # any type
      else:
        raiseInvalid("Invalid type description: " & element)
    valid.add element

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

proc reqQuotationOfSymbols*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isSymbol:
      raiseInvalid("A quotation of symbols is required on the stack")

proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isString and b.isString or a.isNumber and b.isNumber):
    raiseInvalid("Two numbers or two strings are required on the stack")

proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation and not a.isString:
    raiseInvalid("A quotation or a string is required on the stack")

proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not (a.isQuotation and b.isQuotation or a.isString and b.isString):
    raiseInvalid("Two quotations or two strings are required on the stack")

proc reqTwoSimilarTypesNonSymbol*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not ((a.kind == a.kind or (a.isNumber and a.isNumber)) and not a.isSymbol):
    raiseInvalid("Two non-symbol values of similar type are required on the stack")
