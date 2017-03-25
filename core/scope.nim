import
  strutils,
  critbits
import
  parser

proc copy*(s: ref MinScope): ref MinScope =
  var scope = newScope(s.parent)
  scope.symbols = s.symbols
  new(result)
  result[] = scope
  
proc getSymbol*(scope: ref MinScope, key: string): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif not scope.parent.isNil:
    return scope.parent.getSymbol(key)
  else:
    raiseUndefined("Symbol '$1' not found." % key)

proc hasSymbol*(scope: ref MinScope, key: string): bool =
  if scope.isNil:
    return false
  elif scope.symbols.hasKey(key):
    return true
  elif not scope.parent.isNil:
    return scope.parent.hasSymbol(key)
  else:
    return false

proc delSymbol*(scope: ref MinScope, key: string): bool {.discardable.}=
  if scope.symbols.hasKey(key):
    if scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key) 
    scope.symbols.excl(key)
    return true
  return false

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator, override = false): bool {.discardable.}=
  result = false
  # check if a symbol already exists in current scope
  if not scope.isNil and scope.symbols.hasKey(key):
    if not override and scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key) 
    scope.symbols[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the symbol
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value)

proc getSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif not scope.parent.isNil:
    return scope.parent.getSigil(key)
  else:
    raiseUndefined("Sigil '$1' not found." % key)

proc hasSigil*(scope: ref MinScope, key: string): bool =
  if scope.isNil:
    return false
  elif scope.sigils.hasKey(key):
    return true
  elif not scope.parent.isNil:
    return scope.parent.hasSigil(key)
  else:
    return false

proc previous*(scope: ref MinScope): ref MinScope =
  if scope.parent.isNil:
    return scope 
  else:
    return scope.parent
