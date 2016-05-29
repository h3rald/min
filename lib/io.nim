import tables, os, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

# I/O 


define("io")
  
  .symbol("newline") do (i: In):
    echo ""

  .symbol("put") do (i: In):
    let a = i.peek
    echo $$a

  .symbol("get") do (i: In):
    i.push newVal(stdin.readLine())

  .symbol("print") do (i: In):
    let a = i.peek
    a.print

  .symbol("read") do (i: In):
    let a = i.pop
    if a.isString:
      if a.strVal.fileExists:
        try:
          i.push newVal(a.strVal.readFile)
        except:
          warn getCurrentExceptionMsg()
      else:
        warn "File '$1' not found" % [a.strVal]
    else:
      i.error(errIncorrect, "A string is required on the stack")

  .symbol("write") do (i: In):
    let a = i.pop
    let b = i.pop
    if a.isString and b.isString:
      try:
        a.strVal.writeFile(b.strVal)
      except:
        warn getCurrentExceptionMsg()
    else:
      i.error(errIncorrect, "Two strings are required on the stack")

  .finalize()
