import 
  tables,
  random
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils
  
# Operations on sequences (data quotations)
proc seq_module*(i: In)=

  i.define()

    .symbol("harvest") do (i: In):
      discard

    .finalize("seq")
