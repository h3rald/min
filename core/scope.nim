import critbits, strutils
import 
  types


proc lookupSymbol*(scope: ref MinScope, key: string): MinOperator =
  if scope.symbols.hasKey(key):
    return scope.symbols[key]
  elif scope.parent != nil:
    return scope.parent.lookupSymbol(key)

proc lookupSigil*(scope: ref MinScope, key: string): MinOperator =
  if scope.sigils.hasKey(key):
    return scope.sigils[key]
  elif scope.parent != nil:
    return scope.parent.lookupSigil(key)

proc lookupLocal*(scope: ref MinScope, key: string): MinValue =
  if scope.locals.hasKey(key):
    return scope.locals[key]
