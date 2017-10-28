import 
  tables,
  math
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

  # Trigonometry
  
proc trig_module*(i: In)=

  let def = i.define()
  
  def.symbol("sin") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(sin(a.intVal.float))
    else:
      i.push newVal(sin(a.floatVal))
 
  def.symbol("cos") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(cos(a.intVal.float))
    else:
      i.push newVal(cos(a.floatVal))

  def.symbol("tan") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(tan(a.intVal.float))
    else:
      i.push newVal(tan(a.floatVal))

  def.symbol("sinh") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(sinh(a.intVal.float))
    else:
      i.push newVal(sinh(a.floatVal))

  def.symbol("cosh") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(cosh(a.intVal.float))
    else:
      i.push newVal(cosh(a.floatVal))

  def.symbol("tanh") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(tanh(a.intVal.float))
    else:
      i.push newVal(tanh(a.floatVal))

  def.symbol("asin") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(arcsin(a.intVal.float))
    else:
      i.push newVal(arcsin(a.floatVal))

  def.symbol("acos") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(arccos(a.intVal.float))
    else:
      i.push newVal(arccos(a.floatVal))

  def.symbol("atan") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(arctan(a.intVal.float))
    else:
      i.push newVal(arctan(a.floatVal))

  def.symbol("dtr") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(degToRad(a.intVal.float))
    else:
      i.push newVal(degToRad(a.floatVal))

  def.symbol("rtg") do (i: In):
    let vals = i.expect("num")
    let a = vals[0]
    if a.isInt:
      i.push newVal(radToDeg(a.intVal.float))
    else:
      i.push newVal(radToDeg(a.floatVal))

  def.finalize("trig")
