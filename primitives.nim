import tables, strutils
import parser, interpreter, utils

minsym "dup":
  i.push i.peek

minsym "pop":
  discard i.pop

minsym "swap":
  let a = i.pop
  let b = i.pop
  i.push a
  i.push b

minsym "quote":
  let a = i.pop
  i.push TMinValue(kind: minQuotation, qVal: @[a])

minsym "i":
  discard

minsym "print":
  let a = i.peek
  a.print
  echo ""

minsym "def":
  var q = i.pop
  var v = i.pop
  if q.qVal.len != 1 or q.qVal[0].kind != minSymbol:
    i.error(errNoQuotation, "Definition quotation not found on the stack.")
  if v.qVal.len != 1 or q.qVal[0].kind != minSymbol:
    i.error(errNoQuotation, "Value quotation not found on the stack.")
  let defname = q.qVal[0].symVal
  let value = v.qVal[0]
  case value.kind:
    of minSymbol:
      if SYMBOLS.hasKey value.symVal:
        SYMBOLS[defname] = SYMBOLS[value.symVal] 
      else:
        i.error(errUndefined, "Undefined symbol: '"&value.symVal&"'")
    else:
      SYMBOLS[defname] = proc(i: var TMinInterpreter) = i.push value

minalias ":", "def"
minalias "bind", "def"
