import
  critbits,
  json
import
  parser,
  scope

proc typeName*(v: MinValue): string {.extern:"min_exported_symbol_$1".}=
  case v.kind:
    of JInt:
      return "int"
    of JFloat:
      return "float"
    of JObject: 
      if v.isSymbol:
        return "sym"
      elif v.isTypedDictionary:
        return "dict:" & v[";type"].getStr
      else: 
        return "dict"
    of JArray:
      return "quot"
    of JString:
      return "string"
    of JNull:
      return "nil"
    of JBool:
      return "bool"

# Constructors

proc newVal*(s: string): MinValue {.extern:"min_exported_symbol_$1".}=
  return %s

proc newVal*(s: cstring): MinValue {.extern:"min_exported_symbol_$1_2".}=
  return %($s)

proc newVal*(s: seq[MinValue]): MinValue {.extern:"min_exported_symbol_$1_2".}=
  result = newJArray()
  for v in s.items:
    result.add %v

proc newVal*(t: CritBitTree[MinOperator]): MinValue {.extern:"min_exported_symbol_$1_2".}=
  result = newJObject()
  for pair in t.pairs:
    if pair.val.kind == minValOp:
      result[pair.key] = %pair.val.val
    else:
      result[pair.key] = newJObject()
      result[pair.key][";symbol"] = %pair.key

proc newVal*(i: BiggestInt): MinValue {.extern:"min_exported_symbol_$1_4".}=
  return %i

proc newVal*(f: BiggestFloat): MinValue {.extern:"min_exported_symbol_$1_5".}=
  return %f

proc newVal*(s: bool): MinValue {.extern:"min_exported_symbol_$1_6".}=
  return %s

proc newSym*(s: string): MinValue {.extern:"min_exported_symbol_$1".}=
  result = newJObject()
  result[";symbol"] = %s

# Get string value from string or quoted symbol

proc getString*(v: MinValue): string {.extern:"min_exported_symbol_$1".}=
  if v.isSymbol:
    return v.getStr
  elif v.isString:
    return v.getStr
  elif v.isQuotation:
    if v.elems.len != 1:
      raiseInvalid("Quotation is not a quoted symbol")
    let sym = v.elems[0]
    if sym.isSymbol:
      return sym.getStr
    else:
      raiseInvalid("Quotation is not a quoted symbol")
