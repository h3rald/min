import 
  os, 
  strutils,
  logging
import 
  ../packages/nimline/nimline,
  ../packages/nim-sgregex/sgregex,
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
  
    .symbol("notice") do (i: In):
      let a = i.peek
      notice $$a

    .symbol("info") do (i: In):
      let a = i.peek
      info $$a

    .symbol("error") do (i: In):
      let a = i.peek
      error $$a

    .symbol("warn") do (i: In):
      let a = i.peek
      warn $$a

    .symbol("debug") do (i: In):
      let a = i.peek
      debug $$a

    .symbol("fatal") do (i: In):
      let a = i.peek
      fatal $$a
      termRestore()
      quit(100)

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

    .symbol("ask") do (i: In):
      var s: MinValue
      var ed = initEditor()
      i.reqString s
      i.push ed.readLine(s.getString & ": ").newVal

    .symbol("confirm") do (i: In):
      var s: MinValue
      var ed = initEditor()
      i.reqString s
      proc confirm(): bool =
        let answer = ed.readLine(s.getString & " [yes/no]: ")
        if answer.match("^y(es)?$", "i"):
          return true
        elif answer.match("^no?$", "i"):
          return false
        else:
          stdout.write "Invalid answer. Please enter 'yes' or 'no': "
          return confirm()
      i.push confirm().newVal

    .symbol("choose") do (i: In):
      var q, s: MinValue
      var ed = initEditor()
      i.reqStringLikeAndQuotation s, q
      if q.qVal.len <= 0:
        raiseInvalid("No choices to display")
      stdout.writeLine(s.getString)
      proc choose(): int =
        var c = 0
        for item in q.qVal:
          if not item.isQuotation or not item.qVal.len == 2 or not item.qVal[0].isString or not item.qVal[1].isQuotation:
            raiseInvalid("Each item of the quotation must be a quotation containing a string and a quotation")
          c.inc
          echo "$1 - $2" % [$c, item.qVal[0].getString]
        let answer = ed.readLine("Enter your choice ($1 - $2): " % ["1", $c])
        var choice: int
        try:
          choice = answer.parseInt
        except:
          choice = 0
        if choice <= 0 or choice > c:
          echo "Invalid choice."
          return choose()
        else:
          return choice
      let choice = choose()
      i.unquote("<choose>", q.qVal[choice-1].qVal[1])

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
