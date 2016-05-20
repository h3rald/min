import tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# Arithmetic

minsym "+", i:
  let a = i.pop
  let b = i.pop
  if a.isInt:
    if b.isInt:
      i.push newVal(a.intVal + b.intVal)
    elif b.isFloat:
      i.push newVal(a.intVal.float + b.floatVal)
    else:
      i.error(errTwoNumbersRequired)
  elif a.isFloat:
    if b.isFloat:
      i.push newVal(a.floatVal + b.floatVal)
    elif b.isInt:
      i.push newVal(a.floatVal + b.intVal.float)
    else:
      i.error(errTwoNumbersRequired)

minsym "-", i:
  let a = i.pop
  let b = i.pop
  if a.isInt:
    if b.isInt:
      i.push newVal(b.intVal - a.intVal)
    elif b.isFloat:
      i.push newVal(b.floatVal - a.intVal.float)
    else:
      i.error(errTwoNumbersRequired)
  elif a.isFloat:
    if b.isFloat:
      i.push newVal(b.floatVal - a.floatVal)
    elif b.isInt:
      i.push newVal(b.intVal.float - a.floatVal) 
    else:
      i.error(errTwoNumbersRequired)

minsym "*", i:
  let a = i.pop
  let b = i.pop
  if a.isInt:
    if b.isInt:
      i.push newVal(a.intVal * b.intVal)
    elif b.isFloat:
      i.push newVal(a.intVal.float * b.floatVal)
    else:
      i.error(errTwoNumbersRequired)
  elif a.isFloat:
    if b.isFloat:
      i.push newVal(a.floatVal * b.floatVal)
    elif b.isInt:
      i.push newVal(a.floatVal * b.intVal.float)
    else:
      i.error(errTwoNumbersRequired)

minsym "/", i:
  let a = i.pop
  let b = i.pop
  if b.isInt and b.intVal == 0:
    i.error errDivisionByZero
  if a.isInt:
    if b.isInt:
      i.push newVal(b.intVal / a.intVal)
    elif b.isFloat:
      i.push newVal(b.floatVal / a.intVal.float)
    else:
      i.error(errTwoNumbersRequired)
  elif a.isFloat:
    if b.isFloat:
      i.push newVal(b.floatVal / a.floatVal)
    elif b.isInt:
      i.push newVal(b.intVal.float / a.floatVal) 
    else:
      i.error(errTwoNumbersRequired)

minsym "div", i:
  let b = i.pop
  let a = i.pop
  if a.isInt and b.isInt:
    i.push(newVal(a.intVal div b.intVal))
  else:
    i.error errIncorrect, "Two integers are required on the stack"

minsym "mod", i:
  let b = i.pop
  let a = i.pop
  if a.isInt and b.isInt:
    i.push(newVal(a.intVal mod b.intVal))
  else:
    i.error errIncorrect, "Two integers are required on the stack"

