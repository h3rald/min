import
  std/[strutils,
  critbits]
import
  parser

proc copy*(s: ref MinScope): ref MinScope =
  var scope = newScope(s.parent)
  scope.symbols = s.symbols
  scope.sigils = s.sigils
  new(result)
  result[] = scope

proc getSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], acc = 0): MinOperator

proc getSymbol*(scope: ref MinScope, key: string, acc = 0): MinOperator =
  if key.contains ".":
    var keys = key.split(".")
    return getSymbolFromPath(scope, keys, acc)
  elif scope.symbols.hasKey(key):
    return scope.symbols[key]
  else:
    if scope.parent.isNil:
      raiseUndefined("Symbol '$1' not found." % key)
    return scope.parent.getSymbol(key, acc + 1)

proc getSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], acc = 0): MinOperator =
  let sym = keys.pop
  let d = scope.getSymbol(sym, acc)
  if d.kind == minValOp and d.val.kind == minDictionary:
    if keys.len > 2:
      return d.val.scope.getSymbolFromPath(keys, acc + 1)
    else:
      return d.val.scope.getSymbol(keys[1], acc + 1)
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc hasSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool

proc hasSymbol*(scope: ref MinScope, key: string): bool =
  if scope.isNil:
    return false
  elif key.contains ".":
    var keys = key.split(".")
    return hasSymbolFromPath(scope, keys)
  elif scope.symbols.hasKey(key):
    return true
  elif not scope.parent.isNil:
    return scope.parent.hasSymbol(key)
  else:
    return false

proc hasSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool =
  let sym = keys.pop
  let d = scope.getSymbol(sym)
  if d.kind == minValOp and d.val.kind == minDictionary:
    if keys.len > 2:
      return d.val.scope.hasSymbolFromPath(keys)
    else:
      return d.val.scope.hasSymbol(keys[1])
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc delSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool

proc delSymbol*(scope: ref MinScope, key: string): bool {.discardable.} =
  if key.contains ".":
    var keys = key.split(".")
    return delSymbolFromPath(scope, keys)
  elif scope.symbols.hasKey(key):
    if scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed." % key)
    scope.symbols.excl(key)
    return true
  return false

proc delSymbolFromPath(scope: ref MinScope, keys: var seq[
    string]): bool =
  let sym = keys.pop
  let d = scope.getSymbol(sym)
  if d.kind == minValOp and d.val.kind == minDictionary:
    if keys.len > 2:
      return d.val.scope.delSymbolFromPath(keys)
    else:
      return d.val.scope.delSymbol(keys[1])
  else:
    raiseInvalid("Symbol '$1' is not a dictionary." % sym)

proc setSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], value: MinOperator, override = false): bool {.discardable.}

proc setSymbol*(scope: ref MinScope, key: string, value: MinOperator,
    override = false): bool {.discardable.} =
  result = false
  if key.contains ".":
    var keys = key.split(".")
    return setSymbolFromPath(scope, keys, value, override)
  # check if a symbol already exists in current scope
  elif not scope.isNil and scope.symbols.hasKey(key):
    if not override and scope.symbols[key].sealed:
      raiseInvalid("Symbol '$1' is sealed ." % key)
    scope.symbols[key] = value
    result = true
  else:
    # Go up the scope chain and attempt to find the symbol
    if not scope.parent.isNil:
      result = scope.parent.setSymbol(key, value, override)

proc setSymbolFromPath(scope: ref MinScope, keys: var seq[
    string], value: MinOperator, override = false): bool {.discardable.} =
  let sym = keys.pop
  let d = scope.getSymbol(sym)
  if d.kind == minValOp and d.val.kind == minDictionary:
    if keys.len > 2:
      return d.val.scope.setSymbolFromPath(keys, value, override)
    else:
      return d.val.scope.setSymbol(keys[1], value, override)
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
