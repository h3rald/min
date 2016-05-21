import tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

  # Common stack operations
  
define("stack")

  .symbol("id") do (i: In):
    discard
  
  .symbol("pop") do (i: In):
    discard i.pop
  
  .symbol("dup") do (i: In):
    i.push i.peek
  
  .symbol("dip") do (i: In):
    let q = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    let v = i.pop
    for item in q.qVal:
      i.push item
    i.push v
  
  .symbol("swap") do (i: In):
    let a = i.pop
    let b = i.pop
    i.push a
    i.push b
  
  .symbol("sip") do (i: In):
    let a = i.pop
    let b = i.pop
    if a.isQuotation and b.isQuotation:
      i.push b
      i.push a.qVal
      i.push b
    else:
      i.error(errIncorrect, "Two quotations are required on the stack")

  .finalize()
  
