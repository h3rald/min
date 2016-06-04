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

  .symbol("fread") do (i: In):
    var a: MinValue
    i.reqString a
    if a.strVal.fileExists:
      try:
        i.push newVal(a.strVal.readFile)
      except:
        i.error errRuntime, getCurrentExceptionMsg()
    else:
      i.error errRuntime, "File '$1' not found" % [a.strVal]

  .symbol("fwrite") do (i: In):
    var a, b: MinValue
    i.reqTwoStrings a, b
    try:
      a.strVal.writeFile(b.strVal)
    except:
      i.error errRuntime, getCurrentExceptionMsg()

  .symbol("fappend") do (i: In):
    var a, b: MinValue
    i.reqTwoStrings a, b
    try:
      var f:File
      discard f.open(a.strVal, fmAppend)
      f.write(b.strVal)
      f.close()
    except:
       i.error errRuntime, getCurrentExceptionMsg()


  .finalize()
