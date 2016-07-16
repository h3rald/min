import tables, strutils, macros, critbits, httpclient, json, os, regex
import types, parser, interpreter

proc cfgfile*(): string =
  if hostOS == "windows":
    return "HOMEPATH".getEnv / "minconfig.json"
  else:
    return "HOME".getEnv / "minconfig.json"

proc isSymbol*(s: MinValue): bool =
  return s.kind == minSymbol

proc isQuotation*(s: MinValue): bool = 
  return s.kind == minQuotation

proc isString*(s: MinValue): bool = 
  return s.kind == minString

proc isFloat*(s: MinValue): bool =
  return s.kind == minFloat

proc isInt*(s: MinValue): bool =
  return s.kind == minInt

proc isNumber*(s: MinValue): bool =
  return s.kind == minInt or s.kind == minFloat

proc isBool*(s: MinValue): bool =
  return s.kind == minBool

proc isStringLike*(s: MinValue): bool =
  return s.isSymbol or s.isString or (s.isQuotation and s.qVal.len == 1 and s.qVal[0].isSymbol)

proc isObject*(a: MinValue, t: string): bool =
  return a.isQuotation and not a.objType.isNil and a.objType == t

proc isObject*(a: MinValue): bool =
  return a.isQuotation and not a.objType.isNil 

proc newVal*(s: string): MinValue =
  return MinValue(kind: minString, strVal: s)

proc newVal*(s: cstring): MinValue =
  return MinValue(kind: minString, strVal: $s)

proc newVal*(q: seq[MinValue]): MinValue =
  return MinValue(kind: minQuotation, qVal: q)

proc newVal*(s: BiggestInt): MinValue =
  return MinValue(kind: minInt, intVal: s)

proc newVal*(s: BiggestFloat): MinValue =
  return MinValue(kind: minFloat, floatVal: s)

proc newVal*(s: bool): MinValue =
  return MinValue(kind: minBool, boolVal: s)

proc newSym*(s: string): MinValue =
  return MinValue(kind: minSymbol, symVal: s)

# Error Helpers

proc raiseInvalid*(msg: string) =
  raise MinInvalidError(msg: msg)

proc raiseUndefined*(msg: string) =
  raise MinUndefinedError(msg: msg)

proc raiseOutOfBounds*(msg: string) =
  raise MinOutOfBoundsError(msg: msg)

proc raiseRuntime*(msg: string, qVal: var seq[MinValue]) =
  raise MinRuntimeError(msg: msg, qVal: qVal)

proc raiseEmptyStack*() =
  raise MinEmptyStackError(msg: "Insufficient items on the stack")

proc raiseServer*(code: HttpCode, msg: string) = 
  raise MinServerError(msg: msg, code: code)

proc getString*(v: MinValue): string =
  if v.isSymbol:
    return v.symVal
  elif v.isString:
    return v.strVal
  elif v.isQuotation:
    if v.qVal.len != 1:
      raiseInvalid("Quotation is not a quoted symbol")
    let sym = v.qVal[0]
    if sym.isSymbol:
      return sym.symVal
    else:
      raiseInvalid("Quotation is not a quoted symbol")

proc warn*(s: string) =
  stderr.writeLine s

proc previous*(scope: ref MinScope): ref MinScope =
  if scope.parent.isNil:
    return scope #### was: ROOT
  else:
    return scope.parent

proc replace*[T](c: var CritBitTree, s: string, v: T): T {.discardable.}=
  if c.hasKey(s):
    c.excl(s)
  c[s] = v

proc define*(i: In, name: string): ref MinScope =
  var scope = new MinScope
  scope.name = name
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperator): ref MinScope =
  scope.symbols[sym] = p
  return scope

proc sigil*(scope: ref MinScope, sym: string, p: MinOperator): ref MinScope =
  scope.previous.sigils[sym] = p
  return scope

proc finalize*(scope: ref MinScope) =
  var mdl = newSeq[MinValue](0).newVal
  mdl.scope = scope
  mdl.scope.previous.symbols[scope.name] = proc(i: In) {.gcsafe, closure.} =
    i.evaluating = true
    i.push mdl
    i.evaluating = false

template `<-`*[T](target, source: var T) =
  shallowCopy target, source

template alias*[T](varname: untyped, value: var T) =
  var varname {.inject.}: type(value)
  shallowCopy varname, value

proc to*(q: MinValue, T: typedesc): T =
  return cast[T](q.obj)

# Validators

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

proc reqTwoInts*(i: var MinInterpreter, a, b: var MinValue) =
  a = i.pop
  b = i.pop
  if not a.isInt or not b.isInt:
    raiseInvalid("Two integers are required on the stack")

proc reqQuotation*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")

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

proc reqString*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isString:
    raiseInvalid("A string is required on the stack")

proc reqStringLikeAndQuotation*(i: var MinInterpreter, a, q: var MinValue) =
  a = i.pop
  q = i.pop
  if not a.isStringLike or not q.isQuotation:
    raiseInvalid("A string or symbol and a quotation are required on the stack")

proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isQuotation and not a.isString:
    raiseInvalid("A quotation or a string is required on the stack")

proc reqStringLike*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isStringLike:
    raiseInvalid("A symbol or a string is required on the stack")

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

proc reqObject*(i: var MinInterpreter, t: string, a: var MinValue) =
  a = i.pop
  if not a.isObject(t):
    raiseInvalid("An object of type $1 is required on the stack" % [t])

proc reqObject*(i: var MinInterpreter, a: var MinValue) =
  a = i.pop
  if not a.isObject:
    raiseInvalid("An object is required on the stack")


proc cfgRead(): JsonNode =
  return cfgfile().parseFile

proc cfgWrite(cfg: JsonNode) =
  cfgfile().writeFile(cfg.pretty)  

proc cfgGet*(key: string): JsonNode = 
  return cfgRead()[key]

proc cfgSet*(key: string, value: JsonNode) =
  var cfg = cfgRead()
  cfg[key] = value
  cfg.cfgWrite()

proc `%`*(c: CritBitTree[string]): JsonNode =
  result = newJObject()
  for key, value in c.pairs:
    result[key] = %value

proc critbit*(o: JsonNode): CritBitTree[string] =
  for key, value in o.pairs:
    result[key] = value.getStr

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
      result = newJArray()
      for i in a.qVal:
        result.add %i

proc fromJson*(json: JsonNode): MinValue = 
  case json.kind:
    of JNull:
      result = newSeq[MinValue](0).newVal
    of JBool: 
      result = json.getBVal.newVal
    of JInt:
      result = json.getNum.newVal
    of JFloat:
      result = json.getFNum.newVal
    of JString:
      let s = json.getStr
      if s.match("^;sym:"):
        result = regex.replace(s, "^;sym:", "").newSym
      else:
        result = json.getStr.newVal
    of JObject:
      var res = newSeq[MinValue](0)
      for key, value in json.pairs:
        res.add @[key.newSym, value.fromJson].newVal
      return res.newVal
    of JArray:
      var res = newSeq[MinValue](0)
      for value in json.items:
        res.add value.fromJson
      return res.newVal

