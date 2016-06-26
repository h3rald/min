import tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# Comparison operators

define("logic")

  .symbol(">") do (i: In):
    var n2, n1: MinValue
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

  .symbol(">=") do (i: In):
    var n2, n1: MinValue
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
  
  .symbol("<") do (i: In):
    var n2, n1: MinValue
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
  
  .symbol("<=") do (i: In):
    var n2, n1: MinValue
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
  
  .symbol("==") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    i.push newVal(n1 == n2)
  
  .symbol("!=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    i.push newVal(not (n1 == n2))
  
  # Boolean Logic
  
  .symbol("not") do (i: In):
    var b: MinValue
    i.reqBool b
    i.push newVal(not b.boolVal)
  
  .symbol("and") do (i: In):
    var a, b: MinValue
    i.reqTwoBools a, b
    i.push newVal(a.boolVal and b.boolVal)
  
  .symbol("or") do (i: In):
    var a, b: MinValue
    i.reqTwoBools a, b
    i.push newVal(a.boolVal or b.boolVal)
  
  .symbol("xor") do (i: In):
    var a, b: MinValue
    i.reqTwoBools a, b
    i.push newVal(a.boolVal xor b.boolVal)
  
  .symbol("string?") do (i: In):
    if i.peek.kind == minString:
      i.push true.newVal
    else:
      i.push false.newVal
  
  .symbol("int?") do (i: In):
    if i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  .symbol("float?") do (i: In):
    if i.peek.kind == minFloat:
      i.push true.newVal
    else:
      i.push false.newVal
  
  .symbol("number?") do (i: In):
    if i.peek.kind == minFloat or i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  .symbol("bool?") do (i: In):
    if i.peek.kind == minBool:
      i.push true.newVal
    else:
      i.push false.newVal
  
  .symbol("quotation?") do (i: In):
    if i.peek.kind == minQuotation:
      i.push true.newVal
    else:
      i.push false.newVal

  .symbol("object?") do (i: In):
    if i.peek.isObject:
      i.push true.newVal
    else:
      i.push false.newVal

  .symbol("module?") do (i: In):
    if i.peek.isObject and i.peek.objType == "module":
      i.push true.newVal
    else:
      i.push false.newVal

  .symbol("scope?") do (i: In):
    if i.peek.isObject and i.peek.objType == "scope":
      i.push true.newVal
    else:
      i.push false.newVal

  .finalize()
