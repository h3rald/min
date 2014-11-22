import tables, strutils
import parser, interpreter

proc print*(a: TMinValue) =
  case a.kind:
    of minSymbol:
      stdout.write a.symVal
    of minString:
      stdout.write "\""&a.strVal&"\""
    of minInt:
      stdout.write a.intVal
    of minFloat:
      stdout.write a.floatVal
    of minQuotation:
      stdout.write "[ "
      for i in a.qVal:
        i.print
        stdout.write " "
      stdout.write "]"

template minsym*(name: string, body: stmt): stmt {.immediate.} =
  SYMBOLS[name] = proc (i: var TMinInterpreter) =
    body

proc minalias*(newname: string, oldname: string) =
  SYMBOLS[newname] = SYMBOLS[oldname]

proc isSymbol(s: TMinValue): bool =
  return s.kind == minSymbol

