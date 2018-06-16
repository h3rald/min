import 
  strutils, 
  sequtils,
  critbits,
  json,
  tables,
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
    result[result.len-i-1] = x 

# Library methods

proc define*(i: In): ref MinScope {.extern:"min_exported_symbol_$1".}=
  var scope = new MinScope
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.extern:"min_exported_symbol_$1".}=
  scope.symbols[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc symbol*(scope: ref MinScope, sym: string, v: MinValue) {.extern:"min_exported_symbol_$1_2".}=
  scope.symbols[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.extern:"min_exported_symbol_$1".}=
  scope.sigils[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, v: MinValue) {.extern:"min_exported_symbol_$1_2".}=
  scope.sigils[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc finalize*(scope: ref MinScope, name: string = "") {.extern:"min_exported_symbol_$1".}=
  #TODO Review
  var mdl = newJObject()
  mdl[";symbol"] = %name
  #var mdl = newDict(scope)
  #mdl.scope = scope
  #mdl.objType = "module"
  #let op = proc(i: In) {.closure.} =
  #  i.evaluating = true
  #  i.push mdl
  #  i.evaluating = false
  if name != "":
    scope.previous.symbols[name] = MinOperator(kind: minValOp, val: mdl)

# Dictionary Methods

proc dget*(i: In, q: MinValue, s: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q[s.getString]

proc dget*(i: In, q: MinValue, s: string): MinValue {.extern:"min_exported_symbol_$1_2".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q[s]

proc dhas*(q: MinValue, s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.contains(s.getString)

proc dhas*(q: MinValue, s: string): bool {.extern:"min_exported_symbol_$1_2".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.contains(s)

proc ddel*(i: In, p: var MinValue, s: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  delete(p, s.getString)
  return p
      
proc ddel*(i: In, p: var MinValue, s: string): MinValue {.discardable, extern:"min_exported_symbol_$1_2".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  delete(p, s)
  return p
      
proc dset*(i: In, p: var MinValue, s: MinValue, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  p[s.getString] = m
  return p

proc dset*(i: In, p: var MinValue, s: string, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1_2".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  p[s] = m
  return p

proc keys*(i: In, q: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  # Assumes q is a dictionary
  return %toSeq(q.getFields.keys)

proc values*(i: In, q: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  # Assumes q is a dictionary
  return %toSeq(q.getFields.values)

# Validators

proc validate(value: MinValue, t: string): bool {.extern:"min_exported_symbol_$1".}=
  case t:
    of "bool":
      return value.isBool
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
    of "float":
      return value.isFloat
    of "string":
      return value.isString
    of "a":
      return true
    else:
      var split = t.split(":")
      # Typed dictionaries 
      if split[0] == "dict":
        if value.isTypedDictionary(split[1]):
          return true
      return false


proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] {.extern:"min_exported_symbol_$1".}=
  let stack = elements.reverse.join(" ")
  let sym = i.currSym.getString
  var valid = newSeq[string](0)
  result = newSeq[MinValue](0)
  let message = proc(invalid: string): string =
    result = "Symbol: $1 - Incorrect values found on the stack:\n" % sym
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
        if validate(value, t):
          res = true
          break
      if not res:
        raiseInvalid(message(value.typeName))
    elif not validate(value, element):
      raiseInvalid(message(value.typeName))
    valid.add element

proc reqQuotationOfQuotations*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.elems:
    if not s.isQuotation:
      raiseInvalid("A quotation of quotations is required on the stack")

proc reqQuotationOfNumbers*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.elems:
    if not s.isNumber:
      raiseInvalid("A quotation of numbers is required on the stack")

proc reqQuotationOfSymbols*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.elems:
    if not s.isSymbol:
      raiseInvalid("A quotation of symbols is required on the stack")

proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  b = i.pop
  if not (a.isString and b.isString or a.isNumber and b.isNumber):
    raiseInvalid("Two numbers or two strings are required on the stack")

proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation and not a.isString:
    raiseInvalid("A quotation or a string is required on the stack")

proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  b = i.pop
  if not (a.isQuotation and b.isQuotation or a.isString and b.isString):
    raiseInvalid("Two quotations or two strings are required on the stack")
