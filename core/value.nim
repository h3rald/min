import
  parser

proc typeName*(v: MinValue): string =
  case v.kind:
    of minInt:
      return "int"
    of minFloat:
      return "float"
    of minDictionary: 
      if v.isTypedDictionary:
        return "dict:" & v.objType
      else: 
        return "dict"
    of minQuotation:
      return "quot"
    of minString:
      return "string"
    of minSymbol:
      return "sym"
    of minNull:
      return "null"
    of minBool:
      return "bool"

# Constructors

proc newNull*(): MinValue =
  return MinValue(kind: minNull)

proc newVal*(s: string): MinValue =
  return MinValue(kind: minString, strVal: s)

proc newVal*(s: cstring): MinValue =
  return MinValue(kind: minString, strVal: $s)

proc newVal*(q: seq[MinValue]): MinValue =
  return MinValue(kind: minQuotation, qVal: q)

proc newVal*(i: BiggestInt): MinValue =
  return MinValue(kind: minInt, intVal: i)

proc newVal*(f: BiggestFloat): MinValue =
  return MinValue(kind: minFloat, floatVal: f)

proc newVal*(s: bool): MinValue =
  return MinValue(kind: minBool, boolVal: s)

proc newDict*(parentScope: ref MinScope): MinValue =
  return MinValue(kind: minDictionary, scope: newScopeRef(parentScope))

proc newSym*(s: string): MinValue =
  return MinValue(kind: minSymbol, symVal: s)

# Get string value from string or quoted symbol

proc getFloat*(v: MinValue): float =
  if v.isInt:
    return v.intVal.float
  elif v.isFloat:
    return v.floatVal
  else:
    raiseInvalid("Value is not a number")

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
