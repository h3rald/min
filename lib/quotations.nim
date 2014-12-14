import tables
import ../core/parser, ../core/interpreter, ../core/utils

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

minsym "at":
  var index = i.pop
  var q = i.pop
  if index.isInt and q.isQuotation:
    i.push q.qVal[index.intVal]
  else:
    i.error errIncorrect, "An integer and a quotation are required on the stack"

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

minsym "times":
  let t = i.pop
  let prog = i.pop
  if t.isInt and prog.isQuotation:
    for c in 1..t.intVal:
      for pitem in prog.qVal:
        i.push pitem
  else:
    i.error errIncorrect, "An integer and a quotation are required on the stack"

minsym "ifte":
  let fpath = i.pop
  let tpath = i.pop
  let check = i.pop
  var stack = i.copystack
  if check.isQuotation and tpath.isQuotation and fpath.isQuotation:
    i.push check.qVal
    let res = i.pop
    i.stack = stack
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

