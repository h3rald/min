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

proc newString*(s: string): TMinValue =
  return TMinValue(kind: minString, strVal: s)

proc newQuotation*(q: seq[TMinValue]): TMinValue =
  return TMinValue(kind: minQuotation, qVal: q)

proc newInt*(s: int): TMinValue =
  return TMinValue(kind: minInt, intVal: s)

proc newFloat*(s: float): TMinValue =
  return TMinValue(kind: minFloat, floatVal: s)
