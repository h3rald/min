import
  std/[strutils, critbits]
import
  parser

proc copy*(s: ref MinScope): ref MinScope =
  var scope = newScope(s.parent)
  scope.symbols = s.symbols
  scope.sigils = s.sigils
  new(result)
  result[] = scope

proc getDictionary(d: MinOperator): MinValue=
  if d.kind == minValOp and d.val.kind == minQuotation and d.val.qVal.len ==
  1 and d.val.qVal[0].kind == minDictionary:
    return d.val.qVal[0]
  elif d.kind == minValOp and d.val.kind == minDictionary:
    return d.val

proc getSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], acc = 0): MinOperator

proc getSymbol*(scope: ref MinScope, key: string, acc = 0): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif key.contains ".":
    var keys = key.split(".")
    return getSymbolFromPath(scope, keys, acc)
  else:
    if scope.parent.isNil:
      raiseUndefined("Unable to retrieve symbol '$1' (not found)." % key)
    return scope.parent.getSymbol(key, acc + 1)

proc getSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], acc = 0): MinOperator =
  let sym = keys[0]
  keys.delete(0)
  let d = scope.getSymbol(sym, acc)
  let dict = d.getDictionary
  if not dict.isNil:
    if keys.len > 1:
      return dict.scope.getSymbolFromPath(keys, acc + 1)
    else:
      return dict.scope.getSymbol(keys[0], acc + 1)
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc hasSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool

proc hasSymbol*(scope: ref MinScope, key: string): bool =
  if scope.isNil:
    return false
  elif scope.symbols.hasKey(key):
    return true
  elif key.contains("."):
    var keys = key.split(".")
    if keys[0] == "":
      raiseInvalid("Symbols cannot start with a dot")
    return hasSymbolFromPath(scope, keys)
  elif not scope.parent.isNil:
    return scope.parent.hasSymbol(key)
  else:
    return false

proc hasSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool =
  let sym = keys[0]
  keys.delete(0)
  let d = scope.getSymbol(sym)
  let dict = d.getDictionary
  if not dict.isNil:
    if keys.len > 1:
      return dict.scope.hasSymbolFromPath(keys)
    else:
      return dict.scope.hasSymbol(keys[0])
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc delSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool

proc delSymbol*(scope: ref MinScope, key: string): bool {.discardable.} =
  if scope.symbols.hasKey(key):
    if scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key)
    scope.symbols.excl(key)
    return true
  elif key.contains ".":
    var keys = key.split(".")
    return delSymbolFromPath(scope, keys)
  return false

proc delSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool =
  let sym = keys[0]
  keys.delete(0)
  let d = scope.getSymbol(sym)
  let dict = d.getDictionary
  if not dict.isNil:
    if keys.len > 1:
      return dict.scope.delSymbolFromPath(keys)
    else:
      return dict.scope.delSymbol(keys[0])
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc setSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], value: MinOperator, override = false): bool {.discardable.}

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator,
    override = false, define = false): bool {.discardable.} =
  result = false
  # check if a symbol already exists in current scope
  if not scope.isNil and scope.symbols.hasKey(key):
    if not override and scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed ." % key)
    scope.symbols[key] = value
    result = true
  elif key.contains ".":
    var keys = key.split(".")
    return setSymbolFromPath(scope, keys, value, override)
  # define new symbol
  elif not scope.isNil and define:
    scope.symbols[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the symbol
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value, override)

proc setSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], value: MinOperator, override = false): bool {.discardable.} =
  let sym = keys[0]
  keys.delete(0)
  let d = scope.getSymbol(sym)
  let dict = d.getDictionary
  if not dict.isNil:
    if keys.len > 1:
      return dict.scope.setSymbolFromPath(keys, value, override)
    else:
      return dict.scope.setSymbol(keys[0], value, override)
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

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

proc delSigil*(scope: ref MinScope, key: string): bool {.discardable.} =
  if scope.sigils.hasKey(key):
    if scope.sigils[key].sealed:
      raiseInvalid("Sigil '$1' is sealed." % key)
    scope.sigils.excl(key)
    return true
  return false

proc setSigil*(scope: ref MinScope, key: string, value: MinOperator,
    override = false): bool {.discardable.} =
  result = false
  # check if a sigil already exists in current scope
  if not scope.isNil and scope.sigils.hasKey(key):
    if not override and scope.sigils[key].sealed:
      raiseInvalid("Sigil '$1' is sealed." % key)
    scope.sigils[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the sigil
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value)

proc previous*(scope: ref MinScope): ref MinScope =
  if scope.parent.isNil:
    return scope
  else:
    return scope.parent
