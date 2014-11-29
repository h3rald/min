import tables, strutils
import parser, interpreter

template minsym*(name: string, body: stmt): stmt {.immediate.} =
  SYMBOLS[name] = proc (i: var TMinInterpreter) =
    body

proc minalias*(newname: string, oldname: string) =
  SYMBOLS[newname] = SYMBOLS[oldname]

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
