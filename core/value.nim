import
  critbits
import
  parser,
  scope

proc typeName*(v: MinValue): string =
  case v.kind:
    of minInt:
      return "int"
    of minFloat:
      return "float"
    of minQuotation:
      return "quot"
    of minString:
      return "string"
    of minSymbol:
      return "sym"
    of minBool:
      return "bool"

# Predicates

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

proc isDictionary*(q: MinValue): bool =
  if not q.isQuotation:
    return false
  if q.qVal.len == 0:
    return true
  for val in q.qVal:
    if not val.isQuotation or val.qVal.len != 2 or not val.qVal[0].isString:
      return false
  return true

# Constructors

proc newVal*(s: string): MinValue =
  return MinValue(kind: minString, strVal: s)

proc newVal*(s: cstring): MinValue =
  return MinValue(kind: minString, strVal: $s)

proc newVal*(q: seq[MinValue], parentScope: ref MinScope): MinValue =
  return MinValue(kind: minQuotation, qVal: q, scope: newScopeRef(parentScope))

proc newVal*(s: BiggestInt): MinValue =
  return MinValue(kind: minInt, intVal: s)

proc newVal*(s: BiggestFloat): MinValue =
  return MinValue(kind: minFloat, floatVal: s)

proc newVal*(s: bool): MinValue =
  return MinValue(kind: minBool, boolVal: s)

proc newSym*(s: string): MinValue =
  return MinValue(kind: minSymbol, symVal: s)

# Get string value from string or quoted symbol

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
