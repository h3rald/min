import tables, strutils, macros, critbits
import types, parser, interpreter

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

proc newVal*(s: string): MinValue =
  return MinValue(kind: minString, strVal: s)

proc newVal*(q: seq[MinValue]): MinValue =
  return MinValue(kind: minQuotation, qVal: q)

proc newVal*(s: int): MinValue =
  return MinValue(kind: minInt, intVal: s)

proc newVal*(s: float): MinValue =
  return MinValue(kind: minFloat, floatVal: s)

proc newVal*(s: bool): MinValue =
  return MinValue(kind: minBool, boolVal: s)

proc isStringLike*(s: MinValue): bool =
  return s.isSymbol or s.isString

proc getString*(v: MinValue): string =
  if v.isSymbol:
    return v.symVal
  elif v.isString:
    return v.strVal

proc warn*(s: string) =
  stderr.writeLine s

proc linrec*(i: var MinInterpreter, p, t, r1, r2: MinValue) =
  i.push p.qVal
  var check = i.pop
  if check.isBool and check.boolVal == true:
    i.push t.qVal
  else:
    i.push r1.qVal
    i.linrec(p, t, r1, r2)
    i.push r2.qVal

proc previous*(scope: ref MinScope): ref MinScope =
  if scope.parent.isNil:
    return ROOT
  else:
    return scope.parent

proc define*(name: string): ref MinScope =
  var scope = new MinScope
  scope.name = name
  scope.parent = INTERPRETER.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperator): ref MinScope =
  scope.symbols[sym] = p
  #if not scope.parent.isNil:
  #  scope.parent.symbols[scope.name & ":" & sym] = p
  return scope

proc sigil*(scope: ref MinScope, sym: string, p: MinOperator): ref MinScope =
  scope.previous.sigils[sym] = p
  return scope

proc finalize*(scope: ref MinScope) =
  var mdl = newSeq[MinValue](0).newVal
  mdl.scope = scope
  mdl.scope.previous.symbols[scope.name] = proc(i: var MinInterpreter) =
    i.evaluating = true
    i.push mdl
    i.evaluating = false

template `<-`*[T](target, source: var T) =
  shallowCopy target, source

template alias*[T](varname: untyped, value: var T) =
  var varname {.inject.}: type(value)
  shallowCopy varname, value
