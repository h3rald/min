import tables, os, strutils
import ../core/parser, ../core/interpreter, ../core/utils

# I/O 

minsym "puts":
  let a = i.peek
  echo a

minsym "gets":
  i.push newVal(stdin.readLine())

minsym "print":
  let a = i.peek
  a.print

minsym "read":
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

minsym "write":
  let a = i.pop
  let b = i.pop
  if a.isString and b.isString:
    try:
      a.strVal.writeFile(b.strVal)
    except:
      warn getCurrentExceptionMsg()
  else:
    i.error(errIncorrect, "Two strings are required on the stack")
