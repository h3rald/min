import times, tables
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# Time

define("time")

  .symbol("timestamp") do (i: In):
    i.push getTime().int.newVal
  
  .symbol("now") do (i: In):
    i.push epochTime().newVal

  .finalize()

