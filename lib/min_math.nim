import 
  math,
  strformat,
  strutils
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

  # Math
  
proc math_module*(i: In)=

  let def = i.define()

  def.symbol("floor") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.floor.newVal
 
  def.symbol("ceil") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.ceil.newVal
 
  def.symbol("trunc") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.trunc.newVal
 
  def.symbol("round") do (i: In):
    let vals = i.expect("int", "num")
    let places = vals[0].intVal.int
    let n = vals[1].getFloat
    var res = ""
    formatValue(res, n, "." & $places & "f")
    i.push parseFloat(res).newVal
 
  def.symbol("e") do (i: In):
    i.push E.newVal
  
  def.symbol("pi") do (i: In):
    i.push PI.newVal
  
  def.symbol("tau") do (i: In):
    i.push TAU.newVal
  
  def.symbol("ln") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.ln.newVal
 
  def.symbol("log2") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.log2.newVal
 
  def.symbol("log10") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.log10.newVal
 
  def.symbol("pow") do (i: In):
    let vals = i.expect("num", "num")
    let y = vals[0].getFloat
    let x = vals[1].getFloat
    i.push x.pow(y).newVal
 
  def.symbol("sqrt") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.sqrt.newVal
 
  def.symbol("sin") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.sin.newVal
 
  def.symbol("cos") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.cos.newVal

  def.symbol("tan") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.tan.newVal

  def.symbol("sinh") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.sinh.newVal

  def.symbol("cosh") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.cosh.newVal

  def.symbol("tanh") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.tanh.newVal

  def.symbol("asin") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.arcsin.newVal

  def.symbol("acos") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.arccos.newVal

  def.symbol("atan") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.arctan.newVal

  def.symbol("d2r") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.degToRad.newVal

  def.symbol("r2g") do (i: In):
    let vals = i.expect("num")
    i.push vals[0].getFloat.radToDeg.newVal

  def.finalize("math")
