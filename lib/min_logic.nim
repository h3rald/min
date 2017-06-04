import 
  tables
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# Comparison operators


proc logic_module*(i: In)=
  let def = i.define()
  
  def.symbol(">") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
        i.push newVal(n1.strVal > n2.strVal)
  
  def.symbol(">=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float >= n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal >= n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal >= n2.intVal.float)
    else:
        i.push newVal(n1.strVal >= n2.strVal)
  
  def.symbol("<") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
        i.push newVal(n1.strVal > n2.strVal)
  
  def.symbol("<=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float >= n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal >= n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal >= n2.intVal.float)
    else:
        i.push newVal(n1.strVal >= n2.strVal)
  
  def.symbol("==") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    i.push newVal(n1 == n2)
  
  def.symbol("!=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    i.push newVal(not (n1 == n2))
  
  # Boolean Logic
  
  def.symbol("not") do (i: In):
    let vals = i.expect("bool")
    let b = vals[0]
    i.push newVal(not b.boolVal)
  
  def.symbol("and") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal and b.boolVal)
  
  def.symbol("or") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal or b.boolVal)
  
  def.symbol("xor") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal xor b.boolVal)
  
  def.symbol("string?") do (i: In):
    if i.peek.kind == minString:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("integer?") do (i: In):
    if i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("float?") do (i: In):
    if i.peek.kind == minFloat:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("number?") do (i: In):
    if i.peek.kind == minFloat or i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("boolean?") do (i: In):
    if i.peek.kind == minBool:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("quotation?") do (i: In):
    if i.peek.kind == minQuotation:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("dictionary?") do (i: In):
    if i.peek.isDictionary:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.finalize("logic")
