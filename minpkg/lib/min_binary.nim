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
    
    i.push newVal(a.intVal and b.intVal)

  def.symbol("bitnot") do (i: In):
    let vals = i.expect("int")
    let a = vals[0]
    
    i.push newVal(not a.intVal)

  def.symbol("bitor") do (i: In):
    let vals = i.expect("int","int")
    let b = vals[0]
    let a = vals[1]
    
    i.push newVal(a.intVal or b.intVal)

    def.symbol("bitxor") do (i: In):
      let vals = i.expect("int","int")
      let b = vals[0]
      let a = vals[1]
      
      i.push newVal(a.intVal xor b.intVal)

  def.finalize("binary")