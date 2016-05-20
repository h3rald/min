import tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# Common stack operations

minsym "id", i:
  discard

minsym "pop", i:
  discard i.pop

minsym "dup", i:
  i.push i.peek

minsym "dip", i:
  let q = i.pop
  if not q.isQuotation:
    i.error errNoQuotation
  let v = i.pop
  for item in q.qVal:
    i.push item
  i.push v

minsym "swap", i:
  let a = i.pop
  let b = i.pop
  i.push a
  i.push b

minsym "sip", i:
  let a = i.pop
  let b = i.pop
  if a.isQuotation and b.isQuotation:
    i.push b
    i.push a.qVal
    i.push b
  else:
    i.error(errIncorrect, "Two quotations are required on the stack")

