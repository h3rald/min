import tables, strutils
import parser, interpreter

proc sortSymbols() = 
  SYMBOLS.sort(proc (a, b):int = return a.key.cmpIgnoreCase(b.key))

proc sortSigils() = 
  SIGILS.sort(proc (a, b):int = return a.key.cmpIgnoreCase(b.key))

template minsym*(name: string, body: stmt): stmt {.immediate.} =
  SYMBOLS[name] = proc (i: var TMinInterpreter) =
    body
    sortSymbols()

template minsigil*(name: char, body: stmt): stmt {.immediate.} =
  SIGILS[name] = proc (i: var TMinInterpreter) =
    body
    sortSigils()

proc isSymbol*(s: TMinValue): bool =
  return s.kind == minSymbol

proc isQuotation*(s: TMinValue): bool = 
  return s.kind == minQuotation

proc isString*(s: TMinValue): bool = 
  return s.kind == minString

proc isFloat*(s: TMinValue): bool =
  return s.kind == minFloat

proc isInt*(s: TMinValue): bool =
  return s.kind == minInt

proc isNumber*(s: TMinValue): bool =
  return s.kind == minInt or s.kind == minFloat

proc isBool*(s: TMinValue): bool =
  return s.kind == minBool

proc newVal*(s: string): TMinValue =
  return TMinValue(kind: minString, strVal: s)

proc newVal*(q: seq[TMinValue]): TMinValue =
  return TMinValue(kind: minQuotation, qVal: q)

proc newVal*(s: int): TMinValue =
  return TMinValue(kind: minInt, intVal: s)

proc newVal*(s: float): TMinValue =
  return TMinValue(kind: minFloat, floatVal: s)

proc newVal*(s: bool): TMinValue =
  return TMinValue(kind: minBool, boolVal: s)

proc warn*(s: string) =
  stderr.writeln s

proc linrec*(i: var TMinInterpreter, p, t, r1, r2: TMinValue) =
  i.push p.qVal
  var check = i.pop
  if check.isBool and check.boolVal == true:
    i.push t.qVal
  else:
    i.push r1.qVal
    i.linrec(p, t, r1, r2)
    i.push r2.qVal
