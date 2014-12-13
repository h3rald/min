import tables
import ../core/interpreter, ../core/utils

# Common stack operations

minsym "id":
  discard

minsym "pop":
  discard i.pop

minsym "dup":
  i.push i.peek

minsym "dip":
  let q = i.pop
  if not q.isQuotation:
    i.error errNoQuotation
  let v = i.pop
  for item in q.qVal:
    i.push item
  i.push v

minsym "swap":
  let a = i.pop
  let b = i.pop
  i.push a
  i.push b

minsym "sip":
  let a = i.pop
  let b = i.pop
  if a.isQuotation and b.isQuotation:
    i.push b
    i.push a.qVal
    i.push b
  else:
    i.error(errIncorrect, "Two quotations are required on the stack")

