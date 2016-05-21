import critbits, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

ROOT

  .symbol("exit") do (i: In):
    quit(0)

  .symbol("symbols") do (i: In):
    var q = newSeq[MinValue](0)
    for s in i.scope.symbols.keys:
      q.add s.newVal
    i.push q.newVal

  .symbol("sigils") do (i: In):
    var q = newSeq[MinValue](0)
    for s in i.scope.sigils.keys:
      q.add s.newVal
    i.push q.newVal

  .symbol("debug?") do (i: In):
    i.push i.debugging.newVal

  .symbol("debug") do (i: In):
    i.debugging = not i.debugging 
    echo "Debugging: $1" % [$i.debugging]

  # Language constructs

  .symbol("set") do (i: In):
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
    if not i.scope.getSymbol(symbol).isNil:
      i.error errSystem, "Symbol '$1' already exists" % [symbol]
    i.scope.symbols[symbol] = proc(i: var MinInterpreter) =
      i.evaluating = true
      i.push q1.qVal
      i.evaluating = false

  .symbol("unset") do (i: In):
    var q1 = i.pop
    if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
      var symbol = q1.qVal[0].symVal
      i.scope.symbols.excl symbol
    else:
      i.error errIncorrect, "The top quotation must contain only one symbol value"

  .symbol("define") do (i: In):
    let name = i.pop
    var code = i.pop
    if not name.isString or not code.isQuotation:
      i.error(errIncorrect, "A string and a quotation are require on the stack")
    let id = name.strVal
    let scope = i.scope
    let stack = i.copystack
    i.scope = new MinScope
    code.scope = i.scope
    i.scope.parent = scope
    for item in code.qVal:
      i.push item 
    let p = proc(i: var MinInterpreter) = 
      i.evaluating = true
      i.push code
      i.evaluating = false
    let symbols = i.scope.symbols
    i.scope = scope
    i.scope.symbols[id] = p
    # Define symbols in parent scope as well
    for sym, val in symbols.pairs:
      i.scope.symbols[id & ":" & sym] = val
    i.stack = stack

  .symbol("import") do (i: In):
    var mdl: MinValue
    try:
      i.scope.getSymbol(i.pop.strVal)(i)
      mdl = i.pop
    except:
      discard
    if not mdl.isQuotation:
      i.error errNoQuotation
    if not mdl.scope.isNil:
      for sym, val in mdl.scope.symbols.pairs:
        i.scope.symbols[sym] = val
  
  .sigil("'") do (i: In):
    i.push(@[MinValue(kind: minSymbol, symVal: i.pop.strVal)].newVal)

  .symbol("sigil") do (i: In):
    var q1 = i.pop
    let q2 = i.pop
    if q1.isString:
      q1 = @[q1].newVal
    if q1.isQuotation and q2.isQuotation:
      if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
        var symbol = q1.qVal[0].symVal
        if symbol.len == 1:
          if not i.scope.getSigil(symbol).isNil:
            i.error errSystem, "Sigil '$1' already exists" % [symbol]
          i.scope.sigils[symbol] = proc(i: var MinInterpreter) =
            i.evaluating = true
            i.push q2.qVal
            i.evaluating = false
        else:
          i.error errIncorrect, "A sigil can only have one character"
      else:
        i.error errIncorrect, "The top quotation must contain only one symbol value"
    else:
      i.error errIncorrect, "Two quotations are required on the stack"

  .symbol("eval") do (i: In):
    let s = i.pop
    if s.isString:
      i.eval s.strVal
    else:
      i.error(errIncorrect, "A string is required on the stack")

  .symbol("load") do (i: In):
    let s = i.pop
    if s.isString:
      i.load s.strVal
    else:
      i.error(errIncorrect, "A string is required on the stack")

  # Operations on the whole stack

  .symbol("clear") do (i: In):
    while i.stack.len > 0:
      discard i.pop

  .symbol("dump") do (i: In):
    echo i.dump

  .symbol("stack") do (i: In):
    var s = i.stack
    i.push s

  # Operations on quotations or strings

  .symbol("concat") do (i: In):
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

  .symbol("first") do (i: In):
    var q = i.pop
    if q.isQuotation:
      i.push q.qVal[0]
    elif q.isString:
      i.push newVal($q.strVal[0])
    else:
      i.error(errIncorrect, "A quotation or a string is required on the stack")

  .symbol("rest") do (i: In):
    var q = i.pop
    if q.isQuotation:
      i.push newVal(q.qVal[1..q.qVal.len-1])
    elif q.isString:
      i.push newVal(q.strVal[1..q.strVal.len-1])
    else:
      i.error(errIncorrect, "A quotation or a string is required on the stack")

  .finalize()
