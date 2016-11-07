import 
  strutils, 
  critbits,
  logging 
import 
  parser, 
  value,
  scope,
  interpreter

# Library methods

proc logLevel*(val: var string): string {.discardable.} =
  var lvl: Level
  case val:
    of "debug":
      lvl = lvlDebug
    of "info":
      lvl = lvlInfo
    of "notice":
      lvl = lvlNotice
    of "warn":
      lvl = lvlWarn
    of "error":
      lvl = lvlError
    of "fatal":
      lvl = lvlFatal
    of "none":
      lvl = lvlNone
    else:
      val = "warn"
      lvl = lvlWarn
  setLogFilter(lvl)
  return val

proc define*(i: In, name: string): ref MinScope =
  var scope = new MinScope
  scope.name = name
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

proc finalize*(scope: ref MinScope) =
  var mdl = newSeq[MinValue](0).newVal(nil)
  mdl.scope = scope
  let op = proc(i: In) {.gcsafe, closure.} =
    i.evaluating = true
    i.push mdl
    i.evaluating = false
  scope.previous.symbols[scope.name] = MinOperator(kind: minProcOp, prc: op)

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
