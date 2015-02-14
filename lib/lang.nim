import tables, strutils
import ../core/parser, ../core/interpreter, ../core/utils

minsym "exit":
  quit(0)

minsym "symbols":
  var q = newSeq[MinValue](0)
  for s in SYMBOLS.keys:
    q.add s.newVal
  i.push q.newVal

minsym "sigils":
  var q = newSeq[MinValue](0)
  for s in SIGILS.keys:
    q.add s.newVal
  i.push q.newVal

minsym "debug?":
  i.push i.debugging.newVal

minsym "debug":
  i.debugging = not i.debugging 
  echo "Debugging: $1" % [$i.debugging]

# Language constructs

minsym "bind":
  var q2 = i.pop # new (can be a quoted symbol or a string)
  var q1 = i.pop # existing (auto-quoted)
  var symbol: string
  if not q1.isQuotation:
    q1 = @[q1].newVal
  if q2.isString:
    symbol = q2.strVal
  elif q2.isQuotation and q2.qVal.len == 1 and q2.qVal[0].kind == minSymbol:
    symbol = q2.qVal[0].symVal
  else:
    i.error errIncorrect, "The top quotation must contain only one symbol value"
  if SYMBOLS.hasKey(symbol):
    i.error errSystem, "Symbol '$1' already exists" % [symbol]
  minsym symbol:
    i.evaluating = true
    i.push q1.qVal
    i.evaluating = false

minsym "unbind":
  var q1 = i.pop
  if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
    var symbol = q1.qVal[0].symVal
    SYMBOLS.del symbol
  else:
    i.error errIncorrect, "The top quotation must contain only one symbol value"

minsigil "'":
  i.push(@[MinValue(kind: minSymbol, symVal: i.pop.strVal)].newVal)

minsym "sigil":
  var q1 = i.pop
  let q2 = i.pop
  if q1.isString:
    q1 = @[q1].newVal
  if q1.isQuotation and q2.isQuotation:
    if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
      var symbol = q1.qVal[0].symVal
      if symbol.len == 1:
        if SIGILS.hasKey(symbol):
          i.error errSystem, "Sigil '$1' already exists" % [symbol]
        minsigil symbol:
          i.evaluating = true
          i.push q2.qVal
          i.evaluating = false
      else:
        i.error errIncorrect, "A sigil can only have one character"
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
