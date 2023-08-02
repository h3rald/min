import 
  strutils, 
  critbits
import 
  baseutils,
  parser, 
  value,
  json,
  scope,
  env,
  interpreter
  
# Library methods

proc define*(i: In): ref MinScope =
  var scope = newScopeRef(i.scope, minNativeScope)
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.effectsOf: p.} =
  scope.symbols[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc symbol*(scope: ref MinScope, sym: string, v: MinValue) =
  scope.symbols[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.effectsOf: p.} =
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
    raiseInvalid("Key '$1' is set to an operator and it cannot be retrieved." % [s.getString])
  result = q.dVal[s.getString].val

proc dget*(i: In, q: MinValue, s: string): MinValue =
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  if q.dVal[s].kind == minProcOp:
    raiseInvalid("Key $1 is set to an operator and it cannot be retrieved." % [s])
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
      raiseInvalid("Dictionary contains operators that cannot be accessed.")
    r.add item.val
  return r.newVal
  
proc pairs*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for key, value in q.dVal.pairs:
    if value.kind == minProcOp:
      raiseInvalid("Dictionary contains operators that cannot be accessed.")
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
    of minCommand:
      return %(";cmd:$1" % [a.getstring])
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
      elif s.startsWith(";cmd:"):
        result = s.replace(";cmd:", "").newCmd
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

proc validate*(i: In, value: MinValue, t: string, generics: var CritBitTree[string]): bool 

proc validateValueType*(i: var MinInterpreter, element: string, value: MinValue, generics: var CritBitTree[string], vTypes: var seq[string], c: int): bool  =
  vTypes.add value.typeName
  let ors = element.split("|")
  for to in ors:
    let ands = to.split("&")
    var andr = true
    for ta in ands:
      var t = ta
      var neg = false
      if t.len > 1 and t[0] == '!':
        t = t[1..t.len-1]
        neg = true
      andr = i.validate(value, t, generics)
      if neg:
        andr = not andr
      if not andr:
        if neg:
          vTypes[c] = t
        else:
          vTypes[c] = value.typeName
          break
    if andr:
      result = true 
      break

proc validateValueType*(i: var MinInterpreter, element: string, value: MinValue): bool  =
  var g: CritBitTree[string]
  var s = newSeq[string](0)
  var c = 0
  return i.validateValueType(element, value, g, s, c)

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
    of "cmd":
      return value.isCommand
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
      let tc = "typeclass:$#" % t
      let ta = "typealias:$#" % t
      if t.contains(":"):
        var split = t.split(":")
        # Typed dictionaries 
        if split[0] == "dict":
          if value.isTypedDictionary(split[1]):
            return true
        return false
      elif i.scope.hasSymbol(ta):
        # Custom type alias
        let element = i.scope.getSymbol(ta).val.getString
        return i.validateValueType(element, value)
      elif i.scope.hasSymbol(tc):
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
  for ta in s.split("|"):
    for to in ta.split("&"):
      var tt = to
      if to.len < 2:
        return false
      if to[0] == '!':
        tt = to[1..to.len-1]
      if not ts.contains(tt) and not tt.startsWith("dict:") and not i.scope.hasSymbol("typeclass:$#" % tt):
        let ta = "typealias:$#" % tt
        if i.scope.hasSymbol(ta):
          return i.validType(i.scope.getSymbol(ta).val.getString)
        return false
  return true
  

# The following is used in operator signatures
proc expect*(i: var MinInterpreter, elements: varargs[string], generics: var CritBitTree[string]): seq[MinValue] =
  if not DEV:
    # Ignore validation, just return elements
    result = newSeq[MinValue](0)
    for el in elements:
      result.add i.pop
    return result
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
  var res = false
  var vTypes = newSeq[string](0)
  var c = 0
  for el in elements:
    let value = i.pop
    result.add value
    res = i.validateValueType(el, value, generics, vTypes, c)
    if res:
      valid.add el
    elif generics.hasKey(el):
      valid.add(generics[el])
    else:
      raiseInvalid(message(vTypes[c], elements, generics))
    c = c+1

# The following is used in expect symbol and native symbol expectations.
proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] =
  var c: CritBitTree[string]
  return i.expect(elements, c)
        
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
