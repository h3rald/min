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

  i.define("num")
  
    .symbol("+") do (i: In):
      var a, b: MinValue
      i.reqTwoNumbers a, b
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
    
    .symbol("-") do (i: In):
      var a, b: MinValue
      i.reqTwoNumbers a, b
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
    
    .symbol("*") do (i: In):
      var a, b: MinValue
      i.reqTwoNumbers a, b
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
    
    .symbol("/") do (i: In):
      var a, b: MinValue
      i.reqTwoNumbers a, b
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
    
    .symbol("div") do (i: In):
      var a, b: MinValue
      i.reqTwoInts b, a
      i.push(newVal(a.intVal div b.intVal))
    
    .symbol("mod") do (i: In):
      var a, b: MinValue
      i.reqTwoInts b, a
      i.push(newVal(a.intVal mod b.intVal))

    .finalize()
