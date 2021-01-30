import 
  strutils, 
  critbits
import 
  baseutils,
  parser, 
  value,
  json,
  scope,
  interpreter
  
# Library methods

proc define*(i: In): ref MinScope =
  var scope = newScopeRef(i.scope, minNativeScope)
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
  var mdl = newDict(scope)
  mdl.scope = scope
  mdl.objType = "module"
  let op = proc(i: In) {.closure.} =
    i.evaluating = true
    i.push mdl
    i.evaluating = false
  if name != "":
    scope.previous.symbols[name] = MinOperator(kind: minProcOp, prc: op)
    
# Dictionary Methods

proc dget*(i: In, q: MinValue, s: MinValue): MinValue =
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  if q.dVal[s.getString].kind == minProcOp:
    raiseInvalid("Key '$1' is set to a native value that cannot be retrieved." % [s.getString])
  result = q.dVal[s.getString].val

proc dget*(i: In, q: MinValue, s: string): MinValue =
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  if q.dVal[s].kind == minProcOp:
    raiseInvalid("Key $1 is set to a native value that cannot be retrieved." % [s])
  result = q.dVal[s].val

proc dhas*(q: MinValue, s: MinValue): bool =
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.dVal.contains(s.getString)

proc dhas*(q: MinValue, s: string): bool =
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.dVal.contains(s)

proc ddel*(i: In, p: var MinValue, s: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  excl(p.scope.symbols, s.getString)
  return p
      
proc ddel*(i: In, p: var MinValue, s: string): MinValue {.discardable, extern:"min_exported_symbol_$1_2".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  excl(p.scope.symbols, s)
  return p
      
proc dset*(i: In, p: var MinValue, s: MinValue, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var q = m
  p.scope.symbols[s.getString] = MinOperator(kind: minValOp, val: q, sealed: false)
  return p

proc dset*(i: In, p: var MinValue, s: string, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1_2".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var q = m
  p.scope.symbols[s] = MinOperator(kind: minValOp, val: q, sealed: false)
  return p

proc keys*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for i in q.dVal.keys:
    r.add newVal(i)
  return r.newVal

proc values*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for item in q.dVal.values:
    if item.kind == minProcOp:
      raiseInvalid("Dictionary contains native values that cannot be accessed.")
    r.add item.val
  return r.newVal
  
proc pairs*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for key, value in q.dVal.pairs:
    if value.kind == minProcOp:
      raiseInvalid("Dictionary contains native values that cannot be accessed.")
    r.add key.newVal
    r.add value.val
  return r.newVal

  # JSON interop

proc `%`*(i: In, a: MinValue): JsonNode =
  case a.kind:
    of minBool:
      return %a.boolVal
    of minNull:
      return newJNull()
    of minSymbol:
      return %(";sym:$1" % [a.getstring])
    of minString:
      return %a.strVal
    of minInt:
      return %a.intVal
    of minFloat:
      return %a.floatVal
    of minQuotation:
      result = newJArray()
      for it in a.qVal:
        result.add(i%it)
    of minDictionary:
      result = newJObject()
      for it in a.dVal.pairs: 
        result[it.key] = i%i.dget(a, it.key)

proc fromJson*(i: In, json: JsonNode): MinValue = 
  case json.kind:
    of JNull:
      result = newNull()
    of JBool: 
      result = json.getBool.newVal
    of JInt:
      result = json.getBiggestInt.newVal
    of JFloat:
      result = json.getFloat.newVal
    of JString:
      let s = json.getStr
      if s.startsWith(";sym:"):
        result = s.replace(";sym:", "").newSym
      else:
        result = json.getStr.newVal
    of JObject:
      var res = newDict(i.scope)
      for key, value in json.pairs:
        discard i.dset(res, key, i.fromJson(value))
      return res
    of JArray:
      var res = newSeq[MinValue](0)
      for value in json.items:
        res.add i.fromJson(value)
      return res.newVal

# Validators

proc basicValidate*(i: In, value: MinValue, t: string): bool =
  case t:
    of "bool":
      return value.isBool
    of "null":
      return value.isNull
    of "int":
      return value.isInt
    of "num":
      return value.isNumber
    of "quot":
      return value.isQuotation
    of "dict":
      return value.isDictionary
    of "'sym":
      return value.isStringLike
    of "sym":
      return value.isSymbol
    of "flt":
      return value.isFloat
    of "str":
      return value.isString
    of "a":
      return true
    else:
      if t.contains(":"):
        var split = t.split(":")
        # Typed dictionaries 
        if split[0] == "dict":
          if value.isTypedDictionary(split[1]):
            return true
        return false
      elif i.scope.hasSymbol("typeclass:$#" % t):
        # Custom type class
        var i2 = i.copy(i.filename)
        i2.withScope():
          i2.push value
          i2.pushSym("typeclass:$#" % t)
          let res = i2.pop
          if not res.isBool:
            raiseInvalid("Type class '$#' does not evaluate to a boolean value ($# was returned instead)" % [t, $res])
          return res.boolVal
      else:
        raiseInvalid("Unknown type '$#'" % t)

proc validate*(i: In, value: MinValue, t: string, generics: var CritBitTree[string]): bool =
  if generics.hasKey(t):
    let ts = generics[t].split("|")
    for tp in ts:
      if i.basicValidate(value, tp):
        generics[t] = tp # lock type for future uses within same signature
        return true
    return false
  return i.basicValidate(value, t)
    
proc validate*(i: In, value: MinValue, t: string): bool =
  return i.basicValidate(value, t)
  
proc validType*(i: In, s: string): bool =
  const ts = ["bool", "null", "int", "num", "flt", "quot", "dict", "'sym", "sym", "str", "a"]
  if ts.contains(s):
    return true
  if i.scope.hasSymbol("typeclass:$#" % s):
    return true
  for tt in s.split("|"):
    if not ts.contains(tt) and not tt.startsWith("dict:") and not i.scope.hasSymbol("typeclass:$#" % tt):
      return false
  return true

proc expect*(i: var MinInterpreter, elements: varargs[string], generics: var CritBitTree[string]): seq[MinValue] =
  let sym = i.currSym.getString
  var valid = newSeq[string](0)
  result = newSeq[MinValue](0)
  let message = proc(invalid: string, elements: varargs[string], generics: CritBitTree[string]): string =
    var pelements = newSeq[string](0)
    for e in elements.reverse:
      if generics.hasKey(e):
        pelements.add(generics[e])
      else:
        pelements.add e
    let stack = pelements.join(" ")
    result = "Incorrect values found on the stack:\n"
    result &= "- expected: " & stack & " $1\n" % sym
    var other = ""
    if valid.len > 0:
      other = valid.reverse.join(" ") & " "
    result &= "- got:      " & invalid & " " & other & sym
  for el in elements:
    var element = el
    let value = i.pop
    result.add value
    var split = element.split("|")
    if split.len > 1:
      var res = false
      for t in split:
        if i.validate(value, t, generics):
          res = true
          break
      if not res:
        raiseInvalid(message(value.typeName, elements, generics))
    elif not i.validate(value, element, generics):
      raiseInvalid(message(value.typeName, elements, generics))
    if generics.hasKey(el):
      valid.add(generics[el])
    else:
      valid.add element
    
proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] =
  let stack = elements.reverse.join(" ")
  let sym = i.currSym.getString
  var valid = newSeq[string](0)
  result = newSeq[MinValue](0)
  let message = proc(invalid: string): string =
    result = "Incorrect values found on the stack:\n"
    result &= "- expected: " & stack & " $1\n" % sym
    var other = ""
    if valid.len > 0:
      other = valid.reverse.join(" ") & " "
    result &= "- got:      " & invalid & " " & other & sym
  for element in elements:
    let value = i.pop
    result.add value
    var split = element.split("|")
    if split.len > 1:
      var res = false
      for t in split:
        if i.validate(value, t):
          res = true
          break
      if not res:
        raiseInvalid(message(value.typeName))
    elif not i.validate(value, element):
      raiseInvalid(message(value.typeName))
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
      
proc reqQuotationOfIntegers*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isInt:
      raiseInvalid("A quotation of integers is required on the stack")

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
