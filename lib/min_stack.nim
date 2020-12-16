import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

proc stack_module*(i: In)=

  let def = i.define()

  def.symbol("clear-stack") do (i: In):
    while i.stack.len > 0:
      discard i.pop

  def.symbol("get-stack") do (i: In):
    i.push i.stack.newVal

  def.symbol("set-stack") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    i.stack = q.qVal
  
  def.symbol("id") do (i: In):
    discard
  
  def.symbol("pop") do (i: In):
    discard i.pop
  
  def.symbol("dup") do (i: In):
    i.push i.peek

  def.symbol("dip") do (i: In):
    let vals = i.expect("quot", "a")
    var q = vals[0]
    let v = vals[1]
    i.dequote(q)
    i.push v

  def.symbol("nip") do (i: In):
    let vals = i.expect("a", "a")
    let a = vals[0]
    i.push a
  
  def.symbol("cleave") do (i: In):
    var q: MinValue
    i.reqQuotationOfQuotations q
    let v = i.pop
    for s in q.qVal:
      var s1 = s
      i.push v
      i.dequote(s1)
  
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
      i.dequote(s1)
      count.dec
  
  def.symbol("keep") do (i: In):
    let vals = i.expect("quot", "a")
    var q = vals[0]
    let v = vals[1]
    i.push v
    i.dequote(q)
    i.push v
  
  def.symbol("swap") do (i: In):
    let vals = i.expect("a", "a")
    let a = vals[0]
    let b = vals[1]
    i.push a
    i.push b

  def.symbol("over") do (i: In):
    let vals = i.expect("a", "a")
    let a = vals[0]
    let b = vals[1]
    i.push b
    i.push a
    i.push b

  def.symbol("pick") do (i: In):
    let vals = i.expect("a", "a", "a")
    let a = vals[0]
    let b = vals[1]
    let c = vals[2]
    i.push c
    i.push b
    i.push a
    i.push c

  def.symbol("rollup") do (i: In):
    let vals = i.expect("a", "a", "a")
    let first = vals[0]
    let second = vals[1]
    let third = vals[2]
    i.push first
    i.push second
    i.push third

  def.symbol("rolldown") do (i: In):
    let vals = i.expect("a", "a", "a")
    let first = vals[0]
    let second = vals[1]
    let third = vals[2]
    i.push second
    i.push first
    i.push third

  def.symbol("cons") do (i: In):
    let vals = i.expect("quot", "a")
    let q = vals[0]
    let v = vals[1]
    q.qVal = @[v] & q.qVal
    i.push q

  def.symbol("swons") do (i: In):
    i.push "swap".newSym
    i.push "cons".newSym
  
  def.symbol("sip") do (i: In):
    let vals = i.expect("quot", "quot")
    var a = vals[0]
    let b = vals[1]
    i.push b
    i.dequote(a)
    i.push b

  def.finalize("stack")
