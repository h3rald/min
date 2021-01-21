import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

proc binary_module*(i: In)=

  let def = i.define()
    
  def.symbol("bitand") do (i: In):
    let vals = i.expect("int","int")
    let b = vals[0]
    let a = vals[1]
    
    i.push newVal(a.intVal mod b.intVal)

  def.finalize("binary")
