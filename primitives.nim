import tables, strutils
import interpreter, utils

minsym "dup", ["any"]:
  STACK.add STACK.peek

minsym "pop", ["any"]:
  discard STACK.pop

minsym "swap", ["any", "any"]:
  let a = STACK.pop
  let b = STACK.pop
  STACK.add a
  STACK.add b

minsym "quote", ["any"]:
  let a = STACK.pop
  STACK.add TMinValue(kind: minQuotation, qVal: @[a])

minsym "i", []:
  discard

minsym "print", ["any"]:
  let a = STACK.peek
  printMinValue a
  echo ""

minsym "def", ["quotation", "any"]:
  var q = STACK.pop
  var v = STACK.pop
  if q.qVal.len != 1 or q.qVal[0].kind != minSymbol:
    q.valueError("def: Definition quotation not found on the stack.")
  if v.qVal.len != 1 or q.qVal[0].kind != minSymbol:
    v.valueError("def: Value quotation not found on the stack.")
  let defname = q.qVal[0].symVal
  let value = v.qVal[0]
  case value.kind:
    of minSymbol:
      if SYMBOLS.hasKey value.symVal:
        SYMBOLS[defname] = SYMBOLS[value.symVal] 
      else:
        value.valueError("Undefined symbol: '"&value.symVal&"'")
    else:
      SYMBOLS[defname] = proc(v: TMinValue) = STACK.add value

minalias ":", "def"
minalias "bind", "def"
