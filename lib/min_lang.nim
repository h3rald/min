import critbits, strutils, os, json
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils,
  ../core/regex


proc lang_module*(i: In) =
  i.scope
    .symbol("exit") do (i: In):
      quit(0)
  
    .symbol("symbols") do (i: In):
      var q = newSeq[MinValue](0)
      var scope = i.scope
      while scope.isNotNil:
        for s in scope.symbols.keys:
          q.add s.newVal
        scope = scope.parent
      i.push q.newVal
  
    .symbol("sigils") do (i: In):
      var q = newSeq[MinValue](0)
      var scope = i.scope
      while scope.isNotNil:
        for s in scope.sigils.keys:
          q.add s.newVal
        scope = scope.parent
      i.push q.newVal
  
    .symbol("config") do (i: In):
      echo cfgfile().readFile

    .symbol("from-json") do (i: In):
      var s: MinValue
      i.reqString s
      i.push s.getString.parseJson.fromJson

    .symbol("to-json") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.push(($(%q)).newVal)

    .symbol("debug?") do (i: In):
      i.push i.debugging.newVal
  
    .symbol("debug") do (i: In):
      i.debugging = not i.debugging 
      echo "Debugging: $1" % [$i.debugging]
  
    # Language constructs
  
    .symbol("define") do (i: In):
      var sym, val: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal
      symbol = sym.getString
      i.debug "[define] " & symbol & " = " & $q1
      i.scope.symbols[symbol] = proc(i: In) =
        i.push q1.qVal
  
    .symbol("bind") do (i: In):
      var sym, val: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal
      symbol = sym.getString
      i.debug "[bind] " & symbol & " = " & $q1
      let res = i.scope.setSymbol(symbol) do (i: In):
        i.push q1.qVal
      if not res:
        raiseUndefined("Attempting to bind undefined symbol: " & symbol)
  
    .symbol("delete") do (i: In):
      var sym: MinValue 
      i.reqStringLike sym
      let res = i.scope.delSymbol(sym.getString) 
      if not res:
        raiseUndefined("Attempting to delete undefined symbol: " & sym.getString)
  
    .symbol("scope") do (i: In):
      var code: MinValue
      i.reqQuotation code
      code.filename = i.filename
      code.objType = "scope"
      i.unquote("<scope>", code)
      i.push @[code].newVal
  
    .symbol("module") do (i: In):
      var code, name: MinValue
      i.reqStringLike name
      i.reqQuotation code
      code.filename = i.filename
      code.objType = "module"
      i.unquote("<module>", code)
      i.scope.symbols[name.getString] = proc(i: In) =
        i.push code
  
    .symbol("object") do (i: In):
      var code, t: MinValue
      i.reqStringLike t
      i.reqQuotation code
      code.filename = i.filename
      code.objType = t.getString
      i.unquote("<object>", code)
      i.push code
  
    .symbol("type") do (i: In):
      var obj: MinValue
      i.reqObject obj
      i.push obj.objType.newVal
  
    .symbol("defines?") do (i: In):
      var obj, s: MinValue
      i.reqStringLike s
      i.reqObject obj
      i.push obj.scope.symbols.hasKey(s.getString).newVal
  
    .symbol("import") do (i: In):
      var mdl, rawName: MinValue
      var name: string
      i.reqStringLike rawName
      name = rawName.getString
      i.scope.getSymbol(name)(i)
      i.reqQuotation mdl
      if mdl.scope.isNotNil:
        for sym, val in mdl.scope.symbols.pairs:
          i.debug "[import] $1:$2" % [i.scope.name, sym]
          i.scope.symbols[sym] = val
    
    .sigil("'") do (i: In):
      i.push(@[MinValue(kind: minSymbol, symVal: i.pop.strVal)].newVal)
  
    .symbol("sigil") do (i: In):
      var q1, q2: MinValue
      i.reqTwoQuotations q1, q2
      if q1.qVal.len == 1 and q1.qVal[0].kind == minSymbol:
        var symbol = q1.qVal[0].symVal
        if symbol.len == 1:
          if i.scope.getSigil(symbol).isNotNil:
            raiseInvalid("Sigil '$1' already exists" % [symbol])
          i.scope.sigils[symbol] = proc(i: In) =
            i.evaluating = true
            i.push q2.qVal
            i.evaluating = false
        else:
          raiseInvalid("A sigil can only have one character")
      else:
        raiseInvalid("The top quotation must contain only one symbol value")
  
    .symbol("eval") do (i: In):
      var s: MinValue
      i.reqString s
      i.eval s.strVal
  
    .symbol("load") do (i: In):
      var s: MinValue
      i.reqStringLike s
      var file = s.getString
      if not file.endsWith(".min"):
        file = file & ".min"
      i.load i.pwd.joinPath(file)
  
   .symbol("with") do (i: In):
     var qscope, qprog: Minvalue
     i.reqTwoQuotations qscope, qprog
     i.unquote("<with-scope>", qscope)
     i.withScope(qscope):
       i.unquote("<with-program>", qprog)
  
    .symbol("call") do (i: In):
      var symbol, q: Minvalue
      i.reqStringLike symbol
      i.reqQuotation  q
      let s = symbol.getString
      let origScope = i.scope
      i.scope = q.scope
      let sProc = i.scope.getSymbol(s)
      if sProc.isNil:
        raiseUndefined("Symbol '$1' not found in scope '$2'" % [s, i.scope.fullname])
      # Restore original quotation
      sProc(i)
      i.scope = origScope
  
    .symbol("inspect") do (i: In):
      var scope: MinValue
      i.reqQuotation scope
      var symbols = newSeq[MinValue](0)
      for s in scope.scope.symbols.keys:
        symbols.add s.newVal
      i.push symbols.newVal
  
    .symbol("raise") do (i: In):
      var err: MinValue
      i.reqQuotation err
      raiseRuntime("($1) $2" % [err.qVal[0].getString, err.qVal[1].getString], err.qVal)
  
    .symbol("try") do (i: In):
      var prog: MinValue
      i.reqQuotation prog
      if prog.qVal.len == 0:
        raiseInvalid("Quotation must contain at least one element")
      var code = prog.qVal[0]
      var final, catch: MinValue
      var hasFinally = false
      var hasCatch = false
      if prog.qVal.len > 1:
        catch = prog.qVal[1]
        hasCatch = true
      if prog.qVal.len > 2:
        final = prog.qVal[2]
        hasFinally = true
      if (not code.isQuotation) or (hasCatch and not catch.isQuotation) or (hasFinally and not final.isQuotation):
        raiseInvalid("Quotation must contain at one quotation")
      i.unsafe = true
      try:
        i.unquote("<try-code>", code)
      except MinRuntimeError:
        if not hasCatch:
          return
        i.unsafe = false
        let e = (MinRuntimeError)getCurrentException()
        i.push e.qVal.newVal
        i.unquote("<try-catch>", catch)
      except:
        if not hasCatch:
          return
        i.unsafe = false
        let e = getCurrentException()
        i.push @[regex.replace($e.name, ":.+$", "").newVal, e.msg.newVal].newVal
        i.unquote("<try-catch>", catch)
      finally:
        if hasFinally:
          i.unquote("<try-finally>", final)
  
    # Operations on the whole stack
  
    .symbol("clear") do (i: In):
      while i.stack.len > 0:
        discard i.pop
  
    .symbol("dump") do (i: In):
      echo i.dump
  
    .symbol("getstack") do (i: In):
      i.push i.stack.newVal
  
    .symbol("setstack") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.stack = q.qVal
  
    # Operations on quotations or strings
  
    .symbol("concat") do (i: In):
      var q1, q2: MinValue 
      i.reqTwoQuotationsOrStrings q1, q2
      if q1.isString and q2.isString:
        let s = q2.strVal & q1.strVal
        i.push newVal(s)
      else:
        let q = q2.qVal & q1.qVal
        i.push newVal(q)
  
    .symbol("first") do (i: In):
      var q: MinValue
      i.reqStringOrQuotation q
      if q.isQuotation:
        if q.qVal.len == 0:
          raiseOutOfBounds("Quotation is empty")
        i.push q.qVal[0]
      elif q.isString:
        if q.strVal.len == 0:
          raiseOutOfBounds("String is empty")
        i.push newVal($q.strVal[0])
  
    .symbol("rest") do (i: In):
      var q: MinValue
      i.reqStringOrQuotation q
      if q.isQuotation:
        if q.qVal.len == 0:
          raiseOutOfBounds("Quotation is empty")
        i.push newVal(q.qVal[1..q.qVal.len-1])
      elif q.isString:
        if q.strVal.len == 0:
          raiseOutOfBounds("String is empty")
        i.push newVal(q.strVal[1..q.strVal.len-1])
  
    .symbol("quote") do (i: In):
      let a = i.pop
      i.push MinValue(kind: minQuotation, qVal: @[a])
    
    .symbol("unquote") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.unquote("<unquote>", q)
    
    .symbol("append") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      q.qVal.add v
      i.push q
    
    .symbol("cons") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      q.qVal = @[v] & q.qVal
      i.push q
  
    .symbol("at") do (i: In):
      var index, q: MinValue
      i.reqIntAndQuotation index, q
      if q.qVal.len-1 < index.intVal:
        raiseOutOfBounds("Insufficient items in quotation")
      i.push q.qVal[index.intVal.int]
  
    .symbol("size") do (i: In):
      var q: MinValue
      i.reqStringOrQuotation q
      if q.isQuotation:
        i.push q.qVal.len.newVal
      elif q.isString:
        i.push q.strVal.len.newVal
  
    .symbol("contains") do (i: In):
      let v = i.pop
      var q: MinValue
      i.reqQuotation q
      i.push q.qVal.contains(v).newVal 
    
    .symbol("map") do (i: In):
      var prog, list: MinValue
      i.reqTwoQuotations prog, list
      i.push newVal(newSeq[MinValue](0))
      for litem in list.qVal:
        i.push litem
        i.unquote("<map-quotation>", prog)
        i.apply("swap") 
        i.apply("append") 
    
    .symbol("times") do (i: In):
      var t, prog: MinValue
      i.reqIntAndQuotation t, prog
      if t.intVal < 1:
        raiseInvalid("A non-zero natural number is required")
      for c in 1..t.intVal:
        i.unquote("<times-quotation>", prog)
    
    .symbol("ifte") do (i: In):
      var fpath, tpath, check: MinValue
      i.reqThreeQuotations fpath, tpath, check
      var stack = i.copystack
      i.unquote("<ifte-check>", check)
      let res = i.pop
      i.stack = stack
      if res.isBool and res.boolVal == true:
        i.unquote("<ifte-true>", tpath)
      else:
        i.unquote("<ifte-false>", fpath)
    
    .symbol("while") do (i: In):
      var d, b: MinValue
      i.reqTwoQuotations d, b
      i.push b.qVal
      i.unquote("<while-check>", b)
      var check = i.pop
      while check.isBool and check.boolVal == true:
        i.unquote("<while-quotation>", d)
        i.unquote("<while-check>", b)
        check = i.pop
    
    .symbol("filter") do (i: In):
      var filter, list: MinValue
      i.reqTwoQuotations filter, list
      var res = newSeq[MinValue](0)
      for e in list.qVal:
        i.push e
        i.unquote("<filter-check>", filter)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          res.add e
      i.push res.newVal
    
    .symbol("linrec") do (i: In):
      var r2, r1, t, p: MinValue
      i.reqFourQuotations r2, r1, t, p
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
    
    .finalize()
