import tables, strutils
import interpreter

proc printMinValue*(a: TMinValue) =
  case a.kind:
    of minSymbol:
      stdout.write a.symVal
    of minString:
      stdout.write "\""&a.strVal&"\""
    of minInt:
      stdout.write a.intVal
    of minFloat:
      stdout.write a.floatVal
    of minQuotation:
      stdout.write "[ "
      for i in a.qVal:
        printMinValue i
        stdout.write " "
      stdout.write "]"

proc valueError*(s: TMinValue, msg: string) =
  stderr.writeln("$1 [c:$3] Error - $4" %[s.file, $s.first, $s.last, msg])
  quit(1)

proc peek*(s: TMinStack, i = 1): TMinValue =
  return s[s.len-i]

proc expects*(sym: string, reqs: openarray[string]) =
  var i = 0
  var a: TMinValue
  for r in reqs:
    inc(i)
    a = STACK.peek(i)
    if r != "any" and a.kind != TYPES[r]:
      a.valueError("$1: Value #$2 is not a $3" % [sym, $i, r])

template minsym*(name: string, reqs: openarray[string], body: stmt): stmt =
  SYMBOLS[name] = proc (val: TMinValue) =
    let n_req = reqs.len
    let n_found = STACK.len
    if n_found < n_req:
      val.valueError("$1: Not enough values on the stack (required: $2, found: $3)." % [name, $n_req, $n_found])
    name.expects reqs
    body

proc minalias*(newname: string, oldname: string) =
  SYMBOLS[newname] = SYMBOLS[oldname]
