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
    var q = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    let v = i.pop
    i.unquote("<dip>", q)
    i.push v
  
  .symbol("swap") do (i: In):
    let a = i.pop
    let b = i.pop
    i.push a
    i.push b
  
  .symbol("sip") do (i: In):
    var a = i.pop
    let b = i.pop
    if a.isQuotation and b.isQuotation:
      i.push b
      i.unquote("<sip>", a)
      i.push b
    else:
      i.error(errIncorrect, "Two quotations are required on the stack")

  .finalize()
  
