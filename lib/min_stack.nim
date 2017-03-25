import 
  tables,
  random
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils
  
# Operations on the whole stack
proc stack_module*(i: In)=

  i.define("stack")
  
    .symbol("id") do (i: In):
      discard
    
    .symbol("pop") do (i: In):
      if i.stack.len < 1:
        raiseEmptyStack()
      discard i.pop
    
    .symbol("dup") do (i: In):
      i.push i.peek
    
    .symbol("dip") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.unquote("<dip>", q)
      i.push v
    
    .symbol("swap") do (i: In):
      if i.stack.len < 2:
        raiseEmptyStack()
      let a = i.pop
      let b = i.pop
      i.push a
      i.push b
    
    .symbol("sip") do (i: In):
      var a, b: MinValue 
      i.reqTwoQuotations a, b
      i.push b
      i.unquote("<sip>", a)
      i.push b
  
    .symbol("clear-stack") do (i: In):
      while i.stack.len > 0:
        discard i.pop
  
    .symbol("dump-stack") do (i: In):
      echo i.dump
  
    .symbol("get-stack") do (i: In):
      i.push i.stack.newVal(i.scope)
  
    .symbol("set-stack") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.stack = q.qVal
  

    .finalize()
