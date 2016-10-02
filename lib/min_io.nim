import 
  os, 
  strutils
import 
  ../core/linedit,
  ../core/regex,
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# I/O 


proc io_module*(i: In) =
  i.define("io")
    
    .symbol("newline") do (i: In):
      echo ""
  
    .symbol("puts") do (i: In):
      let a = i.peek
      echo $$a
  
    .symbol("column-print") do (i: In):
      var n, q: MinValue
      i.reqIntAndQuotation n, q
      var c = 0
      for s in q.qVal:
        c.inc
        stdout.write $$s & spaces(max(0, 15 - ($$s).len))
        if c mod n.intVal == 0:
          echo ""
      echo ""
  
    .symbol("gets") do (i: In):
      var ed = initEditor()
      i.push ed.readLine().newVal

    .symbol("password") do (i: In):
      var ed = initEditor()
      i.push ed.password("Enter Password: ").newVal

    .symbol("confirm") do (i: In):
      var s: MinValue
      var ed = initEditor()
      i.reqString s
      stdout.write(s.getString & " [yes/no]: ")
      proc confirm(): bool =
        let answer = ed.readLine()
        if answer.match("^y(es)?$", "i"):
          return true
        elif answer.match("^no?$", "i"):
          return false
        else:
          stdout.write "Invalid answer. Please enter 'yes' or 'no': "
          return confirm()
      i.push confirm().newVal
  
    .symbol("print") do (i: In):
      let a = i.peek
      a.print
  
    .symbol("fread") do (i: In):
      var a: MinValue
      i.reqString a
      i.push newVal(a.strVal.readFile)
  
    .symbol("fwrite") do (i: In):
      var a, b: MinValue
      i.reqTwoStrings a, b
      a.strVal.writeFile(b.strVal)
  
    .symbol("fappend") do (i: In):
      var a, b: MinValue
      i.reqTwoStrings a, b
      var f:File
      discard f.open(a.strVal, fmAppend)
      f.write(b.strVal)
      f.close()

    .finalize()
