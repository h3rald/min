import tables, strutils
import interpreter

proc valueError(s: TMinValue, msg: string) =
  stderr.writeln("$1 [$2, $3] Error - $4" %[s.file, $s.first, $s.last, msg])
  quit(1)

proc peek(s: TMinStack, i = 1): TMinValue =
  return s[s.len-i]

proc expects(sym: string, reqs: openarray[string]) =
  var i = 0
  var a: TMinValue
  for r in reqs:
    inc(i)
    a = STACK.peek(i)
    if r != "any" and a.kind != TYPES[r]:
      a.valueError("$1: Value #$2 is not a $3" % [sym, $i, r])

template minsym(name: string, reqs: openarray[string], body: stmt): stmt =
  SYMBOLS[name] = proc (val: TMinValue) =
    let n_req = reqs.len
    let n_found = STACK.len
    if n_found < n_req:
      val.valueError("$1: Not enough values on the stack (required: $2, found: $3)." % [name, $n_req, $n_found])
    name.expects reqs
    body

proc alias(newname, oldname) =
  SYMBOLS[newname] = SYMBOLS[oldname]

proc printMinValue(a: TMinValue) =
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

### SYMBOL DEFINITIONS ###

minsym "dup", ["any"]:
  STACK.add STACK.peek

minsym "pop", ["any"]:
  discard STACK.pop

minsym "swap", ["any", "any"]:
  let a = STACK.pop
  let b = STACK.pop
  STACK.add a
  STACK.add b

minsym "quote", ["any"]:
  let a = STACK.pop
  STACK.add TMinValue(kind: minQuotation, qVal: @[a])

minsym "i", []:
  discard

minsym "print", ["any"]:
  let a = STACK[STACK.len-1]
  printMinValue a
  echo ""

minsym "alias", ["quotation", "quotation"]:
  var q = STACK.pop
  var v = STACK.pop
  if q.qVal.len != 1 or q.qVal[0].kind != minSymbol:
    q.valueError("alias: First quoted symbol not found on the stack.")
  let newalias = q.qVal[0].symVal
  if v.qVal.len != 1 or v.qVal[0].kind != minSymbol:
    q.valueError("alias: Second quoted symbol '$1' not found on the stack")
  let orig = v.qVal[0].symVal
  if SYMBOLS.haskey orig:
    SYMBOLS[newalias] = SYMBOLS[orig]
  else:
    v.valueError("alias: Unknown symbol '$1'" % [orig])

