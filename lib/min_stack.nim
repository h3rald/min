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

  i.define()
    
    .symbol("i") do (i: In):
      i.push "unquote".newSym
    
    .symbol("id") do (i: In):
      discard
    
    .symbol("pop") do (i: In):
      if i.stack.len < 1:
        raiseEmptyStack()
      discard i.pop
    
    # (pop) dip
    .symbol("popd") do (i: In):
      i.push newVal(@["pop".newSym], i.scope)
      i.push "dip".newSym

    # ((pop) dip i)     
    .symbol("k") do (i: In):
      i.push newVal(@["pop".newSym], i.scope)
      i.push "dip".newSym
      i.push "i".newSym

    .symbol("dup") do (i: In):
      i.push i.peek
    
    # (dup) dip
    .symbol("dupd") do (i: In):
      i.push newVal(@["dup".newSym], i.scope)
      i.push "dip".newSym

    #((dup) dip i)
    .symbol("q") do (i: In):
      i.push newVal(@["dup".newSym], i.scope)
      i.push "dip".newSym
      i.push "i".newSym

    .symbol("dip") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.unquote(q)
      i.push v
    
    # ((dip) cons cons)       
    .symbol("take") do (i: In):
      i.push newVal(@["dip".newSym], i.scope)
      i.push "cons".newSym
      i.push "cons".newSym

    .symbol("swap") do (i: In):
      if i.stack.len < 2:
        raiseEmptyStack()
      let a = i.pop
      let b = i.pop
      i.push a
      i.push b

    # (swap) dip
    .symbol("swapd") do (i: In):
      i.push newVal(@["swap".newSym], i.scope)
      i.push "dip".newSym
    
    # ((cons) dip i)            
    .symbol("c") do (i: In):
      i.push newVal(@["swap".newSym], i.scope)
      i.push "dip".newSym
      i.push "i".newSym
    
    .symbol("cons") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      q.qVal = @[v] & q.qVal
      i.push q

    # (() cons dip)         
    .symbol("dig1") do (i: In):
      i.push newVal(@[], i.scope)
      i.push "cons".newSym
      i.push "dip".newSym
    
    # (() cons cons dip)         
    .symbol("dig2") do (i: In):
      i.push newVal(@[], i.scope)
      i.push "cons".newSym
      i.push "cons".newSym
      i.push "dip".newSym
    
    # (() cons cons cons dip)         
    .symbol("dig3") do (i: In):
      i.push newVal(@[], i.scope)
      i.push "cons".newSym
      i.push "cons".newSym
      i.push "cons".newSym
      i.push "dip".newSym

    # ((() cons) dip swap i)
    .symbol("bury1") do (i: In):
      i.push newVal(@[newVal(@[], i.scope), "cons".newSym], i.scope)
      i.push "dip".newSym
      i.push "swap".newSym
      i.push "i".newSym
    
    # ((() cons cons) dip swap i)
    .symbol("bury2") do (i: In):
      i.push newVal(@[newVal(@[], i.scope), "cons".newSym, "cons".newSym], i.scope)
      i.push "dip".newSym
      i.push "swap".newSym
      i.push "i".newSym

    # ((() cons cons cons) dip swap i)
    .symbol("bury3") do (i: In):
      i.push newVal(@[newVal(@[], i.scope), "cons".newSym, "cons".newSym, "cons".newSym], i.scope)
      i.push "dip".newSym
      i.push "swap".newSym
      i.push "i".newSym

    .symbol("swons") do (i: In):
      i.push "swap".newSym
      i.push "cons".newSym
    
    .symbol("sip") do (i: In):
      var a, b: MinValue 
      i.reqTwoQuotations a, b
      i.push b
      i.unquote(a)
      i.push b
  
    .finalize("stack")
