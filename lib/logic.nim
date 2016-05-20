import tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# Comparison operators

minsym ">", i:
  let n2 = i.pop
  let n1 = i.pop
  if n1.isNumber and n2.isNumber:
    if n1.isInt and n2.isInt:
      i.push newVal(n1.intVal > n2.intVal)
    elif n1.isInt and n2.isFloat:
      i.push newVal(n1.intVal.float > n2.floatVal)
    elif n1.isFloat and n2.isFloat:
      i.push newVal(n1.floatVal > n2.floatVal)
    elif n1.isFloat and n2.isInt:
      i.push newVal(n1.floatVal > n2.intVal.float)
  elif n1.isString and n2.isString:
      i.push newVal(n1.strVal > n2.strVal)
  else:
    i.error(errIncorrect, "Two numbers or two strings are required on the stack")

minsym ">=", i:
  let n2 = i.pop
  let n1 = i.pop
  if n1.isNumber and n2.isNumber:
    if n1.isInt and n2.isInt:
      i.push newVal(n1.intVal >= n2.intVal)
    elif n1.isInt and n2.isFloat:
      i.push newVal(n1.intVal.float >= n2.floatVal)
    elif n1.isFloat and n2.isFloat:
      i.push newVal(n1.floatVal >= n2.floatVal)
    elif n1.isFloat and n2.isInt:
      i.push newVal(n1.floatVal >= n2.intVal.float)
  elif n1.isString and n2.isString:
      i.push newVal(n1.strVal >= n2.strVal)
  else:
    i.error(errIncorrect, "Two numbers or two strings are required on the stack")

minsym "<", i:
  let n1 = i.pop
  let n2 = i.pop
  if n1.isNumber and n2.isNumber:
    if n1.isInt and n2.isInt:
      i.push newVal(n1.intVal > n2.intVal)
    elif n1.isInt and n2.isFloat:
      i.push newVal(n1.intVal.float > n2.floatVal)
    elif n1.isFloat and n2.isFloat:
      i.push newVal(n1.floatVal > n2.floatVal)
    elif n1.isFloat and n2.isInt:
      i.push newVal(n1.floatVal > n2.intVal.float)
  elif n1.isString and n2.isString:
      i.push newVal(n1.strVal > n2.strVal)
  else:
    i.error(errIncorrect, "Two numbers or two strings are required on the stack")

minsym "<=", i:
  let n1 = i.pop
  let n2 = i.pop
  if n1.isNumber and n2.isNumber:
    if n1.isInt and n2.isInt:
      i.push newVal(n1.intVal >= n2.intVal)
    elif n1.isInt and n2.isFloat:
      i.push newVal(n1.intVal.float >= n2.floatVal)
    elif n1.isFloat and n2.isFloat:
      i.push newVal(n1.floatVal >= n2.floatVal)
    elif n1.isFloat and n2.isInt:
      i.push newVal(n1.floatVal >= n2.intVal.float)
  elif n1.isString and n2.isString:
      i.push newVal(n1.strVal >= n2.strVal)
  else:
    i.error(errIncorrect, "Two numbers or two strings are required on the stack")

minsym "==", i:
  let n2 = i.pop
  let n1 = i.pop
  if (n1.kind == n2.kind or (n1.isNumber and n2.isNumber)) and not n1.isSymbol:
    i.push newVal(n1 == n2)
  else:
    i.error(errIncorrect, "Two non-symbol values of similar type are required")

minsym "!=", i:
  let n2 = i.pop
  let n1 = i.pop
  if (n1.kind == n2.kind or (n1.isNumber and n2.isNumber)) and not n1.isSymbol:
    i.push newVal(not (n1 == n2))
  else:
    i.error(errIncorrect, "Two non-symbol values of similar type are required")

# Boolean Logic

minsym "not", i:
  let b = i.pop
  if b.isBool:
    i.push newVal(not b.boolVal)
  else:
    i.error(errIncorrect, "A bool value is required on the stack")

minsym "and", i:
  let a = i.pop
  let b = i.pop
  if a.isBool and b.isBool:
    i.push newVal(a.boolVal and b.boolVal)
  else:
    i.error(errIncorrect, "Two bool values are required on the stack")

minsym "or", i:
  let a = i.pop
  let b = i.pop
  if a.isBool and b.isBool:
    i.push newVal(a.boolVal or b.boolVal)
  else:
    i.error(errIncorrect, "Two bool values are required on the stack")

minsym "xor", i:
  let a = i.pop
  let b = i.pop
  if a.isBool and b.isBool:
    i.push newVal(a.boolVal xor b.boolVal)
  else:
    i.error(errIncorrect, "Two bool values are required on the stack")

minsym "string?", i:
  if i.peek.kind == minString:
    i.push true.newVal
  else:
    i.push false.newVal

minsym "int?", i:
  if i.peek.kind == minInt:
    i.push true.newVal
  else:
    i.push false.newVal

minsym "float?", i:
  if i.peek.kind == minFloat:
    i.push true.newVal
  else:
    i.push false.newVal

minsym "number?", i:
  if i.peek.kind == minFloat or i.peek.kind == minInt:
    i.push true.newVal
  else:
    i.push false.newVal

minsym "bool?", i:
  if i.peek.kind == minBool:
    i.push true.newVal
  else:
    i.push false.newVal

minsym "quotation?", i:
  if i.peek.kind == minQuotation:
    i.push true.newVal
  else:
    i.push false.newVal
