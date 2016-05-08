import tables, strutils
import parser, interpreter


template minsym*(name: string, i: expr, body: stmt): stmt {.immediate.} =
  bind SYMBOLS
  SYMBOLS[name] = proc (i: var MinInterpreter) {.closure.} =
    body

template minsigil*(name: char, i: expr, body: stmt): stmt {.immediate.} =
  SIGILS[name] = proc (i: var MinInterpreter) =
    body

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
