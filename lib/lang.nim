import critbits, strutils, os
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
    var scope = i.scope
    while not scope.isNil:
      for s in scope.symbols.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal

  .symbol("sigils") do (i: In):
    var q = newSeq[MinValue](0)
    var scope = i.scope
    while not scope.isNil:
      for s in scope.sigils.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal

  .symbol("debug?") do (i: In):
    i.push i.debugging.newVal

  .symbol("debug") do (i: In):
    i.debugging = not i.debugging 
    echo "Debugging: $1" % [$i.debugging]

  # Language constructs

  .symbol("define") do (i: In):
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
      return
    i.debug "[define] " & symbol & " = " & $q1
    i.scope.symbols[symbol] = proc(i: var MinInterpreter) =
      i.push q1.qVal

  .symbol("bind") do (i: In):
    var q2 = i.pop # new (can be a quoted symbol or a string)
    var q1 = i.pop # existing (auto-quoted)
    var symbol: string
    if not q1.isQuotation:
      q1 = @[q1].newVal
    if q2.isStringLike:
      symbol = q2.getString
    elif q2.isQuotation and q2.qVal.len == 1 and q2.qVal[0].kind == minSymbol:
      symbol = q2.qVal[0].symVal
    else:
      i.error errIncorrect, "The top quotation must contain only one symbol value"
      return
    i.debug "[bind] " & symbol & " = " & $q1
    let res = i.scope.setSymbol(symbol) do (i: In):
      i.push q1.qVal
    if not res:
      i.error errRuntime, "Attempting to bind undefined symbol: " & symbol

  .symbol("delete") do (i: In):
    var sym = i.pop
    if not sym.isStringLike:
      i.error errIncorrect, "A string or a symbol are required on the stack"
    let res = i.scope.delSymbol(sym.getString) 
    if not res:
      i.error errRuntime, "Attempting to delete undefined symbol: " & sym.getString

  .symbol("scope") do (i: In):
    var code = i.pop
    if not code.isQuotation:
      i.error errNoQuotation
      return
    code.filename = i.filename
    i.unquote("<scope>", code)
    i.push @[code].newVal

  .symbol("import") do (i: In):
    var mdl: MinValue
    var name: string
    try:
      name = i.pop.strVal
      i.scope.getSymbol(name)(i)
      mdl = i.pop
    except:
      echo getCurrentExceptionMsg()
    if not mdl.isQuotation:
      i.error errNoQuotation
    if not mdl.scope.isNil:
      #echo "MODULE SCOPE PARENT: ", mdl.scope.name
      for sym, val in mdl.scope.symbols.pairs:
        i.debug "[import] $1:$2" % [i.scope.name, sym]
        i.scope.symbols[sym] = val
  
  .sigil("'") do (i: In):
    i.push(@[MinValue(kind: minSymbol, symVal: i.pop.strVal)].newVal)

  .symbol("sigil") do (i: In):
    var q1 = i.pop
    var q2 = i.pop
    if q1.isString:
      q1 = @[q1].newVal
    if q1.isQuotation and q2.isQuotation:
      if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
        var symbol = q1.qVal[0].symVal
        if symbol.len == 1:
          if not i.scope.getSigil(symbol).isNil:
            i.error errSystem, "Sigil '$1' already exists" % [symbol]
            return
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
      var file = s.strVal
      if not file.endsWith(".min"):
        file = file & ".min"
      i.load i.pwd.joinPath(file)
    else:
      i.error(errIncorrect, "A string is required on the stack")


  .symbol("call") do (i: In):
    let symbols = i.pop
    var target = i.pop
    if not symbols.isQuotation or not target.isQuotation:
      i.error errIncorrect, "Two quotations are required on the stack"
    let vals = symbols.qVal
    var q: MinValue
    if vals.len == 0:
      i.error errIncorrect, "No symbol to call"
      return
    let origScope = i.scope
    i.scope = target.scope
    for c in 0..vals.len-1:
      if not vals[c].isStringLike:
        i.error(errIncorrect, "Quotation must contain only symbols or strings")
        return
      let symbol = vals[c].getString
      let qProc = i.scope.getSymbol(symbol)
      if qProc.isNil:
        i.error(errUndefined, "Symbol '$1' not found in scope '$2'" % [symbol, i.scope.fullname])
        return
      qProc(i)
      if vals.len > 1 and c < vals.len-1:
        q = i.pop
        if not q.isQuotation:
          i.error(errIncorrect, "Unable to evaluate symbol '$1'" % [symbol])
          return
        i.scope = q.scope 
    i.scope = origScope

  # Operations on the whole stack

  .symbol("clear") do (i: In):
    while i.stack.len > 0:
      discard i.pop

  .symbol("dump") do (i: In):
    echo i.dump

  .symbol("getstack") do (i: In):
    i.push i.stack.newVal

  .symbol("setstack") do (i: In):
    let q = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
    i.stack = q.qVal

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
      return
    i.unquote("<unquote>", q)
  
  .symbol("append") do (i: In):
    var q = i.pop
    let v = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
      return
    q.qVal.add v
    i.push q
  
  .symbol("cons") do (i: In):
    var q = i.pop
    let v = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
      return
    q.qVal = @[v] & q.qVal
    i.push q

  .symbol("at") do (i: In):
    var index = i.pop
    var q = i.pop
    if index.isInt and q.isQuotation:
      i.push q.qVal[index.intVal]
    else:
      i.error errIncorrect, "An integer and a quotation are required on the stack"

  .symbol("size") do (i: In):
    let q = i.pop
    if q.isQuotation:
      i.push q.qVal.len.newVal
    elif q.isString:
      i.push q.strVal.len.newVal
    else:
      i.error(errIncorrect, "A quotation or a string is required on the stack")

  .symbol("contains") do (i: In):
    let v = i.pop
    let q = i.pop
    if not q.isQuotation:
      i.error errNoQuotation
      return
    i.push q.qVal.contains(v).newVal 
  
  .symbol("map") do (i: In):
    var prog = i.pop
    let list = i.pop
    if prog.isQuotation and list.isQuotation:
      i.push newVal(newSeq[MinValue](0))
      for litem in list.qVal:
        i.push litem
        i.unquote("<map-quotation>", prog)
        i.apply("swap") 
        i.apply("append") 
    else:
      i.error(errIncorrect, "Two quotations are required on the stack")
  
  .symbol("times") do (i: In):
    let t = i.pop
    var prog = i.pop
    if t.isInt and prog.isQuotation:
      for c in 1..t.intVal:
        i.unquote("<times-quotation>", prog)
    else:
      i.error errIncorrect, "An integer and a quotation are required on the stack"
  
  .symbol("ifte") do (i: In):
    var fpath = i.pop
    var tpath = i.pop
    var check = i.pop
    var stack = i.copystack
    if check.isQuotation and tpath.isQuotation and fpath.isQuotation:
      i.unquote("<ifte-check>", check)
      let res = i.pop
      i.stack = stack
      if res.isBool and res.boolVal == true:
        i.unquote("<ifte-true>", tpath)
      else:
        i.unquote("<ifte-false>", fpath)
    else:
      i.error(errIncorrect, "Three quotations are required on the stack")
  
  .symbol("while") do (i: In):
    var d = i.pop
    var b = i.pop
    if b.isQuotation and d.isQuotation:
      i.push b.qVal
      i.unquote("<while-check>", b)
      var check = i.pop
      while check.isBool and check.boolVal == true:
        i.unquote("<while-quotation>", d)
        i.unquote("<while-check>", b)
        check = i.pop
    else:
      i.error(errIncorrect, "Two quotations are required on the stack")
  
  .symbol("filter") do (i: In):
    var filter = i.pop
    let list = i.pop
    var res = newSeq[MinValue](0)
    if filter.isQuotation and list.isQuotation:
      for e in list.qVal:
        i.push e
        i.unquote("<filter-check>", filter)
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
      proc linrec(i: In, p, t, r1, r2: var MinValue) =
        i.unquote("<linrec-predicate>", p)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          i.unquote("<linrec-true>", t)
        else:
          i.unquote("<linrec-r1>", r1)
          i.linrec(p, t, r1, r2)
          i.unquote("<linrec-r2>", r2)
      i.linrec(p, t, r1, r2)
    else:
      i.error(errIncorrect, "Four quotations are required on the stack")
  
  .finalize()
