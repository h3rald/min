import 
  critbits, 
  strutils, 
  json,
  os, 
  algorithm,
  logging
import 
  ../core/consts,
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../packages/nim-sgregex/sgregex,
  ../packages/niftylogger,
  ../packages/nimline/nimline,
  ../core/scope

proc lang_module*(i: In) =
  i.scope
    .symbol("exit") do (i: In):
      termRestore()
      quit(0)
  
    .symbol("symbols") do (i: In):
      var q = newSeq[MinValue](0)
      var scope = i.scope
      while not scope.isNil:
        for s in scope.symbols.keys:
          q.add s.newVal
        scope = scope.parent
      i.push q.newVal(i.scope)

    .symbol("sigils") do (i: In):
      var q = newSeq[MinValue](0)
      var scope = i.scope
      while not scope.isNil:
        for s in scope.sigils.keys:
          q.add s.newVal
        scope = scope.parent
      i.push q.newVal(i.scope)

    .symbol("module-symbols") do (i: In):
      var m: MinValue
      i.reqQuotation m
      var q = newSeq[MinValue](0)
      for s in m.scope.symbols.keys:
        q.add s.newVal
      i.push q.newVal(i.scope)
  
    .symbol("module-sigils") do (i: In):
      var m: MinValue
      i.reqQuotation m
      var q = newSeq[MinValue](0)
      for s in m.scope.sigils.keys:
        q.add s.newVal
      i.push q.newVal(i.scope)
  
    .symbol("from-json") do (i: In):
      var s: MinValue
      i.reqString s
      i.push i.fromJson(s.getString.parseJson)

    .symbol("to-json") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.push(($((%q).pretty)).newVal)
  
    .symbol("loglevel") do (i: In):
      var s: MinValue
      i.reqStringLike s
      var str = s.getString
      echo "Log level: ", setLogLevel(str)
  
    .symbol("loglevel?") do (i: In):
      echo "Log level: ", getLogLevel()
  
    # Language constructs
  
    .symbol("define") do (i: In):
      var sym: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal(i.scope)
      symbol = sym.getString
      if not symbol.match "^[a-zA-Z_][a-zA-Z0-9/!?+*._-]*$":
        raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
      info "[define] $1 = $2" % [symbol, $q1]
      if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
      i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false)
  
    .symbol("bind") do (i: In):
      var sym: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal(i.scope)
      symbol = sym.getString
      info "[bind] $1 = $2" % [symbol, $q1]
      let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1))
      if not res:
        raiseUndefined("Attempting to bind undefined symbol: " & symbol)
  
    .symbol("delete") do (i: In):
      var sym: MinValue 
      i.reqStringLike sym
      let res = i.scope.delSymbol(sym.getString) 
      if not res:
        raiseUndefined("Attempting to delete undefined symbol: " & sym.getString)
  
    .symbol("module") do (i: In):
      var code, name: MinValue
      i.reqStringLike name
      i.reqQuotation code
      code.filename = i.filename
      i.unquote(code)
      info("[module] $1 ($2 symbols)" % [name.getString, $code.scope.symbols.len])
      i.scope.symbols[name.getString] = MinOperator(kind: minValOp, val: @[code].newVal(i.scope))

    .symbol("import") do (i: In):
      var mdl, rawName: MinValue
      var name: string
      i.reqStringLike rawName
      name = rawName.getString
      var op = i.scope.getSymbol(name)
      i.apply(op)
      i.reqQuotation mdl
      info("[import] Importing: $1 ($2 symbols, $3 sigils)" % [name, $mdl.scope.symbols.len, $mdl.scope.sigils.len])
      for sym, val in mdl.scope.symbols.pairs:
        if i.scope.symbols.hasKey(sym) and i.scope.symbols[sym].sealed:
          raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
        i.debug "[import] $1" % [sym]
        i.scope.symbols[sym] = val
      for sig, val in mdl.scope.sigils.pairs:
        if i.scope.sigils.hasKey(sig) and i.scope.sigils[sig].sealed:
          raiseUndefined("Attempting to redefine sealed sigil '$1'" % [sig])
        i.debug "[import] $1" % [sig]
        i.scope.sigils[sig] = val
    
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
      file = i.pwd.joinPath(file)
      info("[load] File: ", file)
      if not file.fileExists:
        raiseInvalid("File '$1' does not exists." % file)
      i.load file
  
   .symbol("with") do (i: In):
     var qscope, qprog: MinValue
     i.reqTwoQuotations qscope, qprog
     if qscope.qVal.len > 0:
       # System modules are empty quotes and don't need to be unquoted
       i.unquote(qscope)
     i.withScope(qscope, qscope.scope):
      for v in qprog.qVal:
        i.push v

    .symbol("publish") do (i: In):
      var qscope, str: MinValue
      i.reqQuotationAndStringLike qscope, str
      let sym = str.getString
      if qscope.scope.symbols.hasKey(sym) and qscope.scope.symbols[sym].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
      let scope = i.scope
      info("[publish] Symbol: $2" % [sym])
      let op = proc(i: In) {.gcsafe, closure.} =
        let origscope = i.scope 
        i.scope = scope
        i.evaluating = true
        i.push sym.newSym
        i.evaluating = false
        i.scope = origscope
      qscope.scope.symbols[sym] = MinOperator(kind: minProcOp, prc: op)

    .symbol("source") do (i: In):
      var s: MinValue
      i.reqStringLike s
      let str = s.getString
      let sym = i.scope.getSymbol(str)
      if sym.kind == minValOp:
        i.push sym.val
      else:
        raiseInvalid("No source available for native symbol '$1'." % str)
  
    .symbol("call") do (i: In):
      var symbol, q: MinValue
      i.reqStringLike symbol
      i.reqQuotation  q
      let s = symbol.getString
      let origScope = i.scope
      i.scope = q.scope
      let sym = i.scope.getSymbol(s)
      i.apply(sym)
      i.scope = origScope
  
    .symbol("raise") do (i: In):
      var err: MinValue
      i.reqDictionary err
      if err.dhas("error".newSym) and err.dhas("message".newSym):
        raiseRuntime("($1) $2" % [err.dget("error".newVal).getString, err.dget("message".newVal).getString], err.qVal)
      else:
        raiseInvalid("Invalid error dictionary")
  
    .symbol("format-error") do (i: In):
      var err: MinValue
      i.reqDictionary err
      if err.dhas("error".newSym) and err.dhas("message".newSym):
        var msg: string
        var list = newSeq[MinValue]()
        list.add err.dget("message".newVal)
        if err.qVal.contains("symbol".newVal):
          list.add err.dget("symbol".newVal)
        if err.qVal.contains("filename".newVal):
          list.add err.dget("filename".newVal)
        if err.qVal.contains("line".newVal):
          list.add err.dget("line".newVal)
        if err.qVal.contains("column".newVal):
          list.add err.dget("column".newVal)
        if list.len <= 1:
          msg = "$1" % $$list[0]
        else:
          msg = "$3($4,$5) `$2`: $1" % [$$list[0], $$list[1], $$list[2], $$list[3], $$list[4]]
        i.push msg.newVal
      else:
        raiseInvalid("Invalid error dictionary")

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
      try:
        i.unquote(code)
      except MinRuntimeError:
        if not hasCatch:
          return
        let e = (MinRuntimeError)getCurrentException()
        i.push e.qVal.newVal(i.scope)
        i.unquote(catch)
      except:
        if not hasCatch:
          return
        let e = getCurrentException()
        var res = newSeq[MinValue](0)
        let err = sgregex.replace($e.name, ":.+$", "")
        res.add @["error".newSym, err.newVal].newVal(i.scope)
        res.add @["message".newSym, e.msg.newVal].newVal(i.scope)
        res.add @["symbol".newSym, i.currSym].newVal(i.scope)
        res.add @["filename".newSym, i.currSym.filename.newVal].newVal(i.scope)
        res.add @["line".newSym, i.currSym.line.newVal].newVal(i.scope)
        res.add @["column".newSym, i.currSym.column.newVal].newVal(i.scope)
        i.push res.newVal(i.scope)
        i.unquote(catch)
      finally:
        if hasFinally:
          i.unquote(final)

    # Operations on quotations
  
    .symbol("concat") do (i: In):
      var q1, q2: MinValue 
      i.reqTwoQuotations q1, q2
      let q = q2.qVal & q1.qVal
      i.push q.newVal(i.scope)
  
    .symbol("first") do (i: In):
      var q: MinValue
      i.reqQuotation q
      if q.qVal.len == 0:
        raiseOutOfBounds("Quotation is empty")
      i.push q.qVal[0]
  
    .symbol("rest") do (i: In):
      var q: MinValue
      i.reqQuotation q
      if q.qVal.len == 0:
        raiseOutOfBounds("Quotation is empty")
      i.push q.qVal[1..q.qVal.len-1].newVal(i.scope)
  
    .symbol("quote") do (i: In):
      let a = i.pop
      i.push @[a].newVal(i.scope)
    
    .symbol("unquote") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.unquote(q)
    
    .symbol("append") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.push newVal(q.qVal & v, i.scope)
    
    .symbol("prepend") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.push newVal(v & q.qVal, i.scope)
    
    .symbol("at") do (i: In):
      var index, q: MinValue
      i.reqIntAndQuotation index, q
      if q.qVal.len-1 < index.intVal:
        raiseOutOfBounds("Insufficient items in quotation")
      i.push q.qVal[index.intVal.int]
  
    .symbol("size") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.push q.qVal.len.newVal
  
    .symbol("in?") do (i: In):
      i.reqStackSize(2)
      let v = i.pop
      var q: MinValue
      i.reqQuotation q
      i.push q.qVal.contains(v).newVal 
    
    .symbol("map") do (i: In):
      var prog, list: MinValue
      i.reqTwoQuotations prog, list
      var res = newSeq[MinValue](0)
      for litem in list.qVal:
        i.push litem
        i.unquote(prog)
        res.add i.pop
      i.push res.newVal(i.scope)

    .symbol("apply") do (i: In):
      var prog: MinValue
      i.reqQuotation prog
      i.apply prog

    .symbol("foreach") do (i: In):
      var prog, list: MinValue
      i.reqTwoQuotations prog, list
      for litem in list.qVal:
        i.push litem
        i.unquote(prog)
    
    .symbol("times") do (i: In):
      var t, prog: MinValue
      i.reqIntAndQuotation t, prog
      if t.intVal < 1:
        raiseInvalid("A non-zero natural number is required")
      for c in 1..t.intVal:
        i.unquote(prog)
    
    .symbol("ifte") do (i: In):
      var fpath, tpath, check: MinValue
      i.reqThreeQuotations fpath, tpath, check
      var stack = i.stack
      i.unquote(check)
      let res = i.pop
      i.stack = stack
      if not res.isBool:
        raiseInvalid("Result of check is not a boolean value")
      if res.boolVal == true:
        i.unquote(tpath)
      else:
        i.unquote(fpath)

    .symbol("ift") do (i: In):
      var tpath, check: MinValue
      i.reqTwoQuotations tpath, check
      var stack = i.stack
      i.unquote(check)
      let res = i.pop
      i.stack = stack
      if not res.isBool:
        raiseInvalid("Result of check is not a boolean value")
      if res.boolVal == true:
        i.unquote(tpath)

    # 4 (
    #   ((> 3) ("Greater than 3" put!))
    #   ((< 3) ("Smaller than 3" put!))
    #   ((true) ("Exactly 3" put!))
    # ) case
    .symbol("case") do (i: In):
      var cases: MinValue
      i.reqQuotation cases
      if cases.qVal.len == 0:
        raiseInvalid("Empty case operator")
      var k = 0
      let stack = i.stack
      for c in cases.qVal:
        i.stack = stack
        if not c.isQuotation:
          raiseInvalid("A quotation of quotations is required")
        k.inc
        if c.qVal.len != 2 or not c.qVal[0].isQuotation or not c.qVal[1].isQuotation:
          raiseInvalid("Inner quotations in case operator must contain two quotations")
        var q = c.qVal[0]
        i.unquote(q)
        let res = i.pop
        if not res.isBool():
          raiseInvalid("Result of case #$1 is not a boolean value" % $k)
        if res.boolVal == true:
          var t = c.qVal[1]
          i.unquote(t)
          break
    
    .symbol("reverse") do (i: In):
      var q: MinValue
      i.reqQuotation q
      var res = newSeq[MinValue](0)
      for c in countdown(q.qVal.len-1, 0):
        res.add q.qVal[c]
      i.push res.newVal(i.scope)

    .symbol("while") do (i: In):
      var d, b: MinValue
      i.reqTwoQuotations d, b
      for e in b.qVal:
        i.push e
      i.unquote(b)
      var check = i.pop
      while check.isBool and check.boolVal == true:
        i.unquote(d)
        i.unquote(b)
        check = i.pop
      discard i.pop
    
    .symbol("filter") do (i: In):
      var filter, list: MinValue
      i.reqTwoQuotations filter, list
      var res = newSeq[MinValue](0)
      for e in list.qVal:
        i.push e
        i.unquote(filter)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          res.add e
      i.push res.newVal(i.scope)

    .symbol("any?") do (i: In):
      var filter, list: MinValue
      i.reqTwoQuotations filter, list
      for e in list.qVal:
        i.push e
        i.unquote(filter)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          i.push true.newVal
          return
      i.push false.newVal

    .symbol("all?") do (i: In):
      var filter, list: MinValue
      i.reqTwoQuotations filter, list
      for e in list.qVal:
        i.push e
        i.unquote(filter)
        var check = i.pop
        if check.isBool and check.boolVal == false:
          i.push false.newVal
          break
      i.push true.newVal

    .symbol("sort") do (i: In):
      var cmp, list: MinValue
      i.reqTwoQuotations cmp, list
      var i2 = i
      var minCmp = proc(a, b: MinValue): int {.closure.}=
        i2.push a
        i2.push b
        i2.unquote(cmp)
        let r = i2.pop
        if r.isBool:
          if r.boolVal == true:
            return 1
          else:
            return -1
        else:
          raiseInvalid("Predicate quotation must return a boolean value")
      var qList = list.qVal
      sort[MinValue](qList, minCmp)
      i.push qList.newVal(i.scope)
    
    .symbol("linrec") do (i: In):
      var r2, r1, t, p: MinValue
      i.reqFourQuotations r2, r1, t, p
      proc linrec(i: In, p, t, r1, r2: var MinValue) =
        i.unquote(p)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          i.unquote(t)
        else:
          i.unquote(r1)
          i.linrec(p, t, r1, r2)
          i.unquote(r2)
      i.linrec(p, t, r1, r2)

    .symbol("dhas?") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push d.dhas(k).newVal

    .symbol("dget") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push d.dget(k)
      
    .symbol("dset") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      let m = i.pop
      i.reqDictionary d
      i.push i.dset(d, k, m) 

    .symbol("ddel") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push i.ddel(d, k)

    .symbol("keys") do (i: In):
      var d: MinValue
      i.reqDictionary d
      i.push i.keys(d)

    .symbol("values") do (i: In):
      var d: MinValue
      i.reqDictionary d
      i.push i.values(d)

    .symbol("version") do (i: In):
      i.push version.newVal

    # Save/load symbols
    
    .symbol("save-symbol") do (i: In):
      var s:MinValue
      i.reqStringLike s
      let sym = s.getString
      let op = i.scope.getSymbol(sym)
      if op.kind == minProcOp:
        raiseInvalid("Symbol '$1' cannot be serialized." % sym)
      let json = MINSYMBOLS.readFile.parseJson
      json[sym] = %op.val
      MINSYMBOLS.writeFile(json.pretty)

    .symbol("load-symbol") do (i: In):
      var s:MinValue
      i.reqStringLike s
      let sym = s.getString
      let json = MINSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      let val = i.fromJson(json[sym])
      i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val)

    .symbol("stored-symbols") do (i: In):
      var q = newSeq[MinValue](0)
      let json = MINSYMBOLS.readFile.parseJson
      for k,v in json.pairs:
        q.add k.newVal
      i.push q.newVal(i.scope)

    .symbol("remove-symbol") do (i: In):
      var s:MinValue
      i.reqStringLike s
      let sym = s.getString
      var json = MINSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      json.delete(sym)
      MINSYMBOLS.writeFile(json.pretty)

    .symbol("seal") do (i: In):
      var sym: MinValue 
      i.reqStringLike sym
      var s = i.scope.getSymbol(sym.getString) 
      s.sealed = true
      i.scope.setSymbol(sym.getString, s)

    .symbol("unseal") do (i: In):
      var sym: MinValue 
      i.reqStringLike sym
      var s = i.scope.getSymbol(sym.getString) 
      s.sealed = false
      i.scope.setSymbol(sym.getString, s, true)

    .symbol("quote-bind") do (i: In):
      var s, m: MinValue
      i.reqString(s)
      m = i.pop
      i.push @[m].newVal(i.scope)
      i.push s
      i.push "bind".newSym

    .symbol("quote-define") do (i: In):
      var s, m: MinValue
      i.reqString(s)
      m = i.pop
      i.push @[m].newVal(i.scope)
      i.push s
      i.push "define".newSym

    # Sigils

    .sigil("'") do (i: In):
      var s: MinValue
      i.reqString s
      i.push(@[s.strVal.newSym].newVal(i.scope))

    .sigil(":") do (i: In):
      i.push("define".newSym)

    .sigil("~") do (i: In):
      i.push("delete".newSym)

    .sigil("@") do (i: In):
      i.push("bind".newSym)

    .sigil("+") do (i: In):
      i.push("module".newSym)

    .sigil("^") do (i: In):
      i.push("call".newSym)

    .sigil("/") do (i: In):
      i.push("dget".newSym)

    .sigil("%") do (i: In):
      i.push("dset".newSym)

    .sigil(">") do (i: In):
      i.push("save-symbol".newSym)

    .sigil("<") do (i: In):
      i.push("load-symbol".newSym)

    .sigil("#") do (i: In):
      i.push("quote-bind".newSym)

    .sigil("=") do (i: In):
      i.push("quote-define".newSym)

    # Shorthand symbol aliases

    .symbol(":") do (i: In):
      i.push("define".newSym)

    .symbol("@") do (i: In):
      i.push("bind".newSym)

    .symbol("^") do (i: In):
      i.push("call".newSym)

    .symbol("'") do (i: In):
      i.push("quote".newSym)

    .symbol("->") do (i: In):
      i.push("unquote".newSym)

    .symbol("=>") do (i: In):
      i.push("apply".newSym)

    .finalize("ROOT")
