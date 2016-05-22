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
    var scope = i.scope.parent
    while not scope.isNil:
      for s in scope.symbols.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal

  .symbol("sigils") do (i: In):
    var q = newSeq[MinValue](0)
    for s in i.scope.parent.sigils.keys:
      q.add s.newVal
    i.push q.newVal

  .symbol("debug?") do (i: In):
    i.push i.debugging.newVal

  .symbol("debug") do (i: In):
    i.debugging = not i.debugging 
    echo "Debugging: $1" % [$i.debugging]

  # Language constructs

  .symbol("let") do (i: In):
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
    i.debug "[let] " & symbol & " = " & $q1
    i.scope.parent.symbols[symbol] = proc(i: var MinInterpreter) =
      i.evaluating = true
      i.push q1.qVal
      i.evaluating = false

  .symbol("bind") do (i: In):
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
    i.debug "[bind] " & symbol & " = " & $q1
    i.scope.setSymbol(symbol) do (i: In):
      i.evaluating = true
      i.push q1.qVal
      i.evaluating = false

  .symbol("unset") do (i: In):
    var q1 = i.pop
    if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
      var symbol = q1.qVal[0].symVal
      i.scope.parent.symbols.excl symbol
    else:
      i.error errIncorrect, "The top quotation must contain only one symbol value"

  .symbol("module") do (i: In):
    let name = i.pop
    var code = i.pop
    if not name.isString or not code.isQuotation:
      i.error(errIncorrect, "A string and a quotation are require on the stack")
    let id = name.strVal
    let scope = i.scope
    let stack = i.copystack
    i.newScope(id, code): #<--
      for item in code.qVal:
        i.push item 
      let p = proc(i: In) = 
        i.evaluating = true
        i.push code
        i.evaluating = false
    i.scope.parent.symbols[id] = p
    i.stack = stack

  .symbol("import") do (i: In):
    var mdl: MinValue
    try:
      i.scope.getSymbol(i.pop.strVal)(i)
      mdl = i.pop
    except:
      echo getCurrentExceptionMsg()
    if not mdl.isQuotation:
      i.error errNoQuotation
    if not mdl.scope.isNil:
      #echo "MODULE SCOPE PARENT: ", mdl.scope.name
      for sym, val in mdl.scope.symbols.pairs:
        i.debug "[$1 - import] $2:$3" % [i.scope.parent.name, i.scope.name, sym]
        i.scope.parent.symbols[sym] = val
  
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
          if i.scope.parent.sigils.hasKey(symbol):
            i.error errSystem, "Sigil '$1' already exists" % [symbol]
          i.scope.parent.sigils[symbol] = proc(i: var MinInterpreter) =
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

  .symbol("quote") do (i: In):
    let a = i.pop
    i.push MinValue(kind: minQuotation, qVal: @[a])
  
  .symbol("unquote") do (i: In):
    var q = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    i.newScope("<unquote-push>", q):
      for item in q.qVal:
        i.push item 
  
  .symbol("append") do (i: In):
    var q = i.pop
    let v = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    q.qVal.add v
    i.push q
  
  .symbol("cons") do (i: In):
    var q = i.pop
    let v = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    q.qVal = @[v] & q.qVal
    i.push q

  .symbol("at") do (i: In):
    var index = i.pop
    var q = i.pop
    if index.isInt and q.isQuotation:
      i.push q.qVal[index.intVal]
    else:
      i.error errIncorrect, "An integer and a quotation are required on the stack"
  
  .symbol("map") do (i: In):
    let prog = i.pop
    let list = i.pop
    if prog.isQuotation and list.isQuotation:
      i.push newVal(newSeq[MinValue](0))
      for litem in list.qVal:
        i.push litem
        for pitem in prog.qVal:
          i.push pitem
        i.apply("swap") 
        i.apply("append") 
    else:
      i.error(errIncorrect, "Two quotations are required on the stack")
  
  .symbol("times") do (i: In):
    let t = i.pop
    let prog = i.pop
    if t.isInt and prog.isQuotation:
      for c in 1..t.intVal:
        for pitem in prog.qVal:
          i.push pitem
    else:
      i.error errIncorrect, "An integer and a quotation are required on the stack"
  
  .symbol("ifte") do (i: In):
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
  
  # TODO test (add new scope?)
  .symbol("while") do (i: In):
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
  
  # TODO test (add new scope?)
  .symbol("filter") do (i: In):
    let filter = i.pop
    let list = i.pop
    var res = newSeq[MinValue](0)
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
  
  .symbol("linrec") do (i: In):
    var r2 = i.pop
    var r1 = i.pop
    var t = i.pop
    var p = i.pop
    if p.isQuotation and t.isQuotation and r1.isQuotation and r2.isQuotation:
      i.linrec(p, t, r1, r2)
    else:
      i.error(errIncorrect, "Four quotations are required on the stack")
  
  .finalize()
