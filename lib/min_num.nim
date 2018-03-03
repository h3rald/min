import 
  tables,
  random
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

  # Arithmetic
  
proc num_module*(i: In)=

  let def = i.define()

  def.symbol("nan") do (i: In):
    i.push newVal(NaN)
  
  def.symbol("inf") do (i: In):
    i.push newVal(Inf)
  
  def.symbol("-inf") do (i: In):
    i.push newVal(NegInf)
  
  def.symbol("+") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal + b.intVal)
      else:
        i.push newVal(a.intVal.float + b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal + b.floatVal)
      else:
        i.push newVal(a.floatVal + b.intVal.float)
  
  def.symbol("-") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(b.intVal - a.intVal)
      else:
        i.push newVal(b.floatVal - a.intVal.float)
    else:
      if b.isFloat:
        i.push newVal(b.floatVal - a.floatVal)
      else:
        i.push newVal(b.intVal.float - a.floatVal) 
  
  def.symbol("*") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal * b.intVal)
      else:
        i.push newVal(a.intVal.float * b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal * b.floatVal)
      else:
        i.push newVal(a.floatVal * b.intVal.float)
  
  def.symbol("/") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(b.intVal.int / a.intVal.int)
      else:
        i.push newVal(b.floatVal / a.intVal.float)
    else:
      if b.isFloat:
        i.push newVal(b.floatVal / a.floatVal)
      else:
        i.push newVal(b.intVal.float / a.floatVal) 
  
  def.symbol("random") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push n.intVal.int.rand.newVal

  def.symbol("div") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push(newVal(a.intVal div b.intVal))
  
  def.symbol("mod") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push(newVal(a.intVal mod b.intVal))

  def.symbol("succ") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal + 1)

  def.symbol("pred") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal - 1)
  
  def.symbol("even?") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal mod 2 == 0)

  def.symbol("odd?") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal mod 2 != 0)

  def.symbol("sum") do (i: In):
    var s: MinValue
    i.reqQuotationOfNumbers s
    var c = 0.float
    var isInt = true
    for n in s.qVal:
      if n.isFloat:
        isInt = false
        c = + n.floatVal
      else:
        c = c + n.intVal.float
    if isInt:
      i.push c.int.newVal
    else:
      i.push c.newVal

  def.finalize("num")
