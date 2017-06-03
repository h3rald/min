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

  let def = i.define()

  def.symbol("clear-stack") do (i: In):
    while i.stack.len > 0:
      discard i.pop

  def.symbol("get-stack") do (i: In):
    i.push i.stack.newVal(i.scope)

  def.symbol("set-stack") do (i: In):
    var q: MinValue
    i.reqQuotation q
    i.stack = q.qVal
  
  def.symbol("id") do (i: In):
    discard
  
  def.symbol("pop") do (i: In):
    if i.stack.len < 1:
      raiseEmptyStack()
    discard i.pop
  
  def.symbol("dup") do (i: In):
    i.push i.peek

  def.symbol("dip") do (i: In):
    var q: MinValue
    i.reqQuotation q
    let v = i.pop
    i.unquote(q)
    i.push v

  def.symbol("nip") do (i: In):
    var a, b: MinValue
    a = i.pop
    b = i.pop
    i.push a
  
  def.symbol("cleave") do (i: In):
    var q: MinValue
    i.reqQuotationOfQuotations q
    let v = i.pop
    for s in q.qVal:
      var s1 = s
      i.push v
      i.unquote(s1)
  
  def.symbol("spread") do (i: In):
    var q: MinValue
    i.reqQuotationOfQuotations q
    var els = newSeq[MinValue](0)
    for el in 0..q.qVal.len-1:
      els.add i.pop
    var count = els.len-1
    for s in q.qVal:
      var s1 = s
      i.push els[count]
      i.unquote(s1)
      count.dec
  
  def.symbol("keep") do (i: In):
    var q: MinValue
    i.reqQuotation q
    let v = i.pop
    i.push v
    i.unquote(q)
    i.push v
  
  def.symbol("swap") do (i: In):
    i.reqStackSize 2
    let a = i.pop
    let b = i.pop
    i.push a
    i.push b

  def.symbol("over") do (i: In):
    i.reqStackSize 2
    let a = i.pop
    let b = i.pop
    i.push b
    i.push a
    i.push b

  def.symbol("pick") do (i: In):
    i.reqStackSize 3
    let a = i.pop
    let b = i.pop
    let c = i.pop
    i.push c
    i.push b
    i.push a
    i.push c

  def.symbol("rollup") do (i: In):
    i.reqStackSize 3
    let first = i.pop
    let second = i.pop
    let third = i.pop
    i.push first
    i.push second
    i.push third

  def.symbol("rolldown") do (i: In):
    i.reqStackSize 3
    let first = i.pop
    let second = i.pop
    let third = i.pop
    i.push second
    i.push first
    i.push third

  def.symbol("cons") do (i: In):
    var q: MinValue
    i.reqQuotation q
    let v = i.pop
    q.qVal = @[v] & q.qVal
    i.push q

  def.symbol("swons") do (i: In):
    i.push "swap".newSym
    i.push "cons".newSym
  
  def.symbol("sip") do (i: In):
    var a, b: MinValue 
    i.reqTwoQuotations a, b
    i.push b
    i.unquote(a)
    i.push b

  def.finalize("stack")
