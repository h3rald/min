import tables, strutils
import ../core/parser, ../core/interpreter, ../core/utils

minsym "exit":
  quit(0)

minsym "symbols":
  var q = newSeq[TMinValue](0)
  for s in SYMBOLS.keys:
    q.add s.newVal
  i.push q.newVal

minsym "aliases":
  var q = newSeq[TMinValue](0)
  for s in ALIASES:
    q.add s.newVal
  i.push q.newVal

minsym "debug?":
  i.push i.debugging.newVal

minsym "debug":
  i.debugging = not i.debugging 
  echo "Debugging: $1" % [$i.debugging]

# Language constructs

minsym "def":
  let q1 = i.pop
  let q2 = i.pop
  if q1.isQuotation and q2.isQuotation:
    if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
      minsym q1.qVal[0].symVal:
        i.evaluating = true
        i.push q2.qVal
        i.evaluating = false
    else:
      i.error errIncorrect, "The top quotation must contain only one symbol value"
  else:
    i.error errIncorrect, "Two quotations are required on the stack"

minsym "eval":
  let s = i.pop
  if s.isString:
    i.eval s.strVal
  else:
    i.error(errIncorrect, "A string is required on the stack")

minsym "load":
  let s = i.pop
  if s.isString:
    i.load s.strVal
  else:
    i.error(errIncorrect, "A string is required on the stack")


# Operations on the whole stack

minsym "clear":
  while i.stack.len > 0:
    discard i.pop

minsym "dump":
  echo i.dump

minsym "stack":
  var s = i.stack
  i.push s

# Operations on quotations

minsym "quote":
  let a = i.pop
  i.push TMinValue(kind: minQuotation, qVal: @[a])

minsym "unquote":
  let q = i.pop
  if not q.isQuotation:
    i.error errNoQuotation
  for item in q.qVal:
   i.push item 

minsym "cons":
  var q = i.pop
  let v = i.pop
  if not q.isQuotation:
    i.error errNoQuotation
  q.qVal.add v
  i.push q

minsym "map":
  let prog = i.pop
  let list = i.pop
  if prog.isQuotation and list.isQuotation:
    i.push newVal(newSeq[TMinValue](0))
    for litem in list.qVal:
      i.push litem
      for pitem in prog.qVal:
        i.push pitem
      i.apply("swap") 
      i.apply("cons") 
  else:
    i.error(errIncorrect, "Two quotations are required on the stack")

minsym "ifte":
  let fpath = i.pop
  let tpath = i.pop
  let check = i.pop
  if check.isQuotation and tpath.isQuotation and fpath.isQuotation:
    i.push check.qVal
    let res = i.pop
    if res.isBool and res.boolVal == true:
      i.push tpath.qVal
    else:
      i.push fpath.qVal
  else:
    i.error(errIncorrect, "Three quotations are required on the stack")

minsym "while":
  let d = i.pop
  let b = i.pop
  if b.isQuotation and d.isQuotation:
    i.push b.qVal
    var check = i.pop
    while check.isBool and check.boolVal == true:
      i.push d.qVal
      i.push b.qVal
      check = i.pop
  else:
    i.error(errIncorrect, "Two quotations are required on the stack")

minsym "filter":
  let filter = i.pop
  let list = i.pop
  var res = newSeq[TMinValue](0)
  if filter.isQuotation and list.isQuotation:
    for e in list.qVal:
      i.push e
      i.push filter.qVal
      var check = i.pop
      if check.isBool and check.boolVal == true:
        res.add e
    i.push res.newVal
  else:
    i.error(errIncorrect, "Two quotations are required on the stack")

minsym "linrec":
  var r2 = i.pop
  var r1 = i.pop
  var t = i.pop
  var p = i.pop
  if p.isQuotation and t.isQuotation and r1.isQuotation and r2.isQuotation:
    i.linrec(p, t, r1, r2)
  else:
    i.error(errIncorrect, "Four quotations are required on the stack")

# Operations on quotations or strings

minsym "concat":
  var q1 = i.pop
  var q2 = i.pop
  if q1.isString and q2.isString:
    let s = q2.strVal & q1.strVal
    i.push newVal(s)
  elif q1.isQuotation and q2.isQuotation:
    let q = q2.qVal & q1.qVal
    i.push newVal(q)
  else:
    i.error(errIncorrect, "Two quotations or two strings are required on the stack")

minsym "first":
  var q = i.pop
  if q.isQuotation:
    i.push q.qVal[0]
  elif q.isString:
    i.push newVal($q.strVal[0])
  else:
    i.error(errIncorrect, "A quotation or a string is required on the stack")

minsym "rest":
  var q = i.pop
  if q.isQuotation:
    i.push newVal(q.qVal[1..q.qVal.len-1])
  elif q.isString:
    i.push newVal(q.strVal[1..q.strVal.len-1])
  else:
    i.error(errIncorrect, "A quotation or a string is required on the stack")

# Operations on strings


minsym "split":
  let sep = i.pop
  let s = i.pop
  if s.isString and sep.isString:
    for e in s.strVal.split(sep.strVal):
      i.push e.newVal
  else:
    i.error errIncorrect, "Two strings are required on the stack"
