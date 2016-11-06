import 
  critbits, 
  strutils, 
  os, 
  json,
  algorithm,
  oids
import 
  ../core/consts,
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../core/regex,
  ../core/linedit,
  ../core/scope

# Dictionary Methods

proc dget*(q: MinValue, s: MinValue): MinValue =
  # Assumes q is a dictionary
  for v in q.qVal:
    if v.qVal[0].getString == s.getString:
      return v.qVal[1]
  raiseInvalid("Key '$1' not found" % s.getString)

proc dhas*(q: MinValue, s: MinValue): bool =
  # Assumes q is a dictionary
  for v in q.qVal:
    if v.qVal[0].getString == s.getString:
      return true
  return false

proc ddel*(i: In, p: MinValue, s: MinValue): MinValue {.discardable.} =
  # Assumes q is a dictionary
  var q = newVal(p.qVal, i.scope)
  var found = false
  var c = -1
  for v in q.qVal:
    c.inc
    if v.qVal[0].getString == s.getString:
      found = true
      break
  if found:
    q.qVal.delete(c)
  return q
      
proc dset*(i: In, p: MinValue, s: MinValue, m: MinValue): MinValue {.discardable.}=
  # Assumes q is a dictionary
  var q = newVal(p.qVal, i.scope)
  var found = false
  var c = -1
  for v in q.qVal:
    c.inc
    if v.qVal[0].getString == s.getString:
      found = true
      break
  if found:
      q.qVal.delete(c)
      q.qVal.insert(@[s.getString.newSym, m].newVal(i.scope), c)
  return q

proc keys*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  result = newSeq[MinValue](0).newVal(i.scope)
  for v in q.qVal:
    result.qVal.add v.qVal[0]

proc values*(i: In, q: MinValue): MinValue =
  # Assumes q is a dictionary
  result = newSeq[MinValue](0).newVal(i.scope)
  for v in q.qVal:
    result.qVal.add v.qVal[1]

# JSON interop

proc `%`*(a: MinValue): JsonNode =
  case a.kind:
    of minBool:
      return %a.boolVal
    of minSymbol:
      return %(";sym:$1" % [a.symVal])
    of minString:
      return %a.strVal
    of minInt:
      return %a.intVal
    of minFloat:
      return %a.floatVal
    of minQuotation:
      if a.isDictionary:
        result = newJObject()
        for i in a.qVal:
          result[$i.qVal[0].symVal] = %i.qVal[1]
      else:
        result = newJArray()
        for i in a.qVal:
          result.add %i

proc fromJson*(i: In, json: JsonNode): MinValue = 
  case json.kind:
    of JNull:
      result = newSeq[MinValue](0).newVal(i.scope)
    of JBool: 
      result = json.getBVal.newVal
    of JInt:
      result = json.getNum.newVal
    of JFloat:
      result = json.getFNum.newVal
    of JString:
      let s = json.getStr
      if s.match("^;sym:"):
        result = regex.replace(s, "^;sym:", "").newSym
      else:
        result = json.getStr.newVal
    of JObject:
      var res = newSeq[MinValue](0)
      for key, value in json.pairs:
        res.add @[key.newSym, i.fromJson(value)].newVal(i.scope)
      return res.newVal(i.scope)
    of JArray:
      var res = newSeq[MinValue](0)
      for value in json.items:
        res.add i.fromJson(value)
      return res.newVal(i.scope)

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
  
    .symbol("from-json") do (i: In):
      var s: MinValue
      i.reqString s
      i.push i.fromJson(s.getString.parseJson)

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
      var sym: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal(i.scope)
      symbol = sym.getString
      if not symbol.match "^[a-zA-Z0-9_][a-zA-Z0-9/!?+*._-]*$":
        raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
      i.debug "[define] (scope: $1) $2 = $3" % [i.scope.fullname, symbol, $q1]
      if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1' on scope '$2'" % [symbol, i.scope.name])
      i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false)
  
    .symbol("bind") do (i: In):
      var sym: MinValue
      i.reqStringLike sym
      var q1 = i.pop # existing (auto-quoted)
      var symbol: string
      if not q1.isQuotation:
        q1 = @[q1].newVal(i.scope)
      symbol = sym.getString
      i.debug "[bind] " & symbol & " = " & $q1
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
      i.unquote("<module>", code, code.scope)
      i.debug("[module] $1 ($2 symbols)" % [name.getString, $code.scope.symbols.len])
      i.scope.symbols[name.getString] = MinOperator(kind: minValOp, val: @[code].newVal(i.scope))

    .symbol("import") do (i: In):
      var mdl, rawName: MinValue
      var name: string
      i.reqStringLike rawName
      name = rawName.getString
      var op = i.scope.getSymbol(name)
      i.apply(op)
      i.reqQuotation mdl
      i.debug("[import] Importing: $1 ($2 symbols)" % [name, $mdl.scope.symbols.len])
      for sym, val in mdl.scope.symbols.pairs:
        i.debug "[import] $1:$2" % [i.scope.fullname, sym]
        i.scope.symbols[sym] = val
    
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
      if not file.fileExists:
        raiseInvalid("File '$1' does not exists." % file)
      i.load file
  
   .symbol("with") do (i: In):
     var qscope, qprog: MinValue
     i.reqTwoQuotations qscope, qprog
     if qscope.qVal.len > 0:
       # System modules are empty quotes and don't need to be unquoted
       i.unquote("<with-scope>", qscope, qscope.scope)
     i.withScope(qscope):
      for v in qprog.qVal:
        i.push v

    .symbol("publish") do (i: In):
      var qscope, str: MinValue
      i.reqQuotationAndStringLike qscope, str
      let sym = str.getString
      if qscope.scope.symbols.hasKey(sym) and qscope.scope.symbols[sym].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1' on scope '$2'" % [sym, qscope.scope.name])
      let scope = i.scope
      i.debug("[publish] (scope: $1) -> $2" % [i.scope.fullname, sym])
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
  
    .symbol("inspect") do (i: In):
      var scope: MinValue
      i.reqQuotation scope
      var symbols = newSeq[MinValue](0)
      if scope.scope.isNil:
        i.push symbols.newVal(i.scope)
      else:
        for s in scope.scope.symbols.keys:
          symbols.add s.newVal
        i.push symbols.newVal(i.scope)
  
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
          msg = "(!) $1" % $$list[0]
        else:
          msg = "(!) $3($4,$5) `$2`: $1" % [$$list[0], $$list[1], $$list[2], $$list[3], $$list[4]]
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
        i.unquote("<try-code>", code)
      except MinRuntimeError:
        if not hasCatch:
          return
        let e = (MinRuntimeError)getCurrentException()
        i.push e.qVal.newVal(i.scope)
        i.unquote("<try-catch>", catch)
      except:
        if not hasCatch:
          return
        let e = getCurrentException()
        var res = newSeq[MinValue](0)
        let err = regex.replace($e.name, ":.+$", "")
        res.add @["error".newSym, err.newVal].newVal(i.scope)
        res.add @["message".newSym, e.msg.newVal].newVal(i.scope)
        res.add @["symbol".newSym, i.currSym].newVal(i.scope)
        res.add @["filename".newSym, i.currSym.filename.newVal].newVal(i.scope)
        res.add @["line".newSym, i.currSym.line.newVal].newVal(i.scope)
        res.add @["column".newSym, i.currSym.column.newVal].newVal(i.scope)
        i.push res.newVal(i.scope)
        i.unquote("<try-catch>", catch)
      finally:
        if hasFinally:
          i.unquote("<try-finally>", final)

    # Operations on the whole stack

    .symbol("id") do (i: In):
      discard
    
    .symbol("pop") do (i: In):
      if i.stack.len < 1:
        raiseEmptyStack()
      discard i.pop
    
    .symbol("dup") do (i: In):
      i.push i.peek
    
    .symbol("dip") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.unquote("<dip>", q)
      i.push v
    
    .symbol("swap") do (i: In):
      if i.stack.len < 2:
        raiseEmptyStack()
      let a = i.pop
      let b = i.pop
      i.push a
      i.push b
    
    .symbol("sip") do (i: In):
      var a, b: MinValue 
      i.reqTwoQuotations a, b
      i.push b
      i.unquote("<sip>", a)
      i.push b
  
    .symbol("clear-stack") do (i: In):
      while i.stack.len > 0:
        discard i.pop
  
    .symbol("dump-stack") do (i: In):
      echo i.dump
  
    .symbol("get-stack") do (i: In):
      i.push i.stack.newVal(i.scope)
  
    .symbol("set-stack") do (i: In):
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
        i.push q.newVal(i.scope)
  
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
        i.push q.qVal[1..q.qVal.len-1].newVal(i.scope)
      elif q.isString:
        if q.strVal.len == 0:
          raiseOutOfBounds("String is empty")
        i.push newVal(q.strVal[1..q.strVal.len-1])
  
    .symbol("quote") do (i: In):
      let a = i.pop
      i.push @[a].newVal(i.scope)
    
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
  
    .symbol("length") do (i: In):
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
      #i.push newVal(newSeq[MinValue](0))
      var res = newSeq[MinValue](0)
      for litem in list.qVal:
        i.push litem
        i.unquote("<map-quotation>", prog)
        res.add i.pop
      i.push res.newVal(i.scope)

    .symbol("foreach") do (i: In):
      var prog, list: MinValue
      i.reqTwoQuotations prog, list
      for litem in list.qVal:
        i.push litem
        #i.debug("[foreach] $1" % prog.scope.fullname)
        i.unquote("<foreach-quotation>", prog)
    
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
      var stack = i.stack
      i.unquote("<ifte-check>", check)
      let res = i.pop
      i.stack = stack
      if not res.isBool:
        raiseInvalid("Result of check is not a boolean value")
      if res.boolVal == true:
        i.unquote("<ifte-true>", tpath)
      else:
        i.unquote("<ifte-false>", fpath)

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
        i.unquote("<case-$1-check>" % $k, q)
        let res = i.pop
        if not res.isBool():
          raiseInvalid("Result of case #$1 is not a boolean value" % $k)
        if res.boolVal == true:
          var t = c.qVal[1]
          i.unquote("<case-$1-true>" % $k, t)

    
    .symbol("while") do (i: In):
      var d, b: MinValue
      i.reqTwoQuotations d, b
      for e in b.qVal:
        i.push e
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
      i.push res.newVal(i.scope)

    .symbol("sort") do (i: In):
      var cmp, list: MinValue
      i.reqTwoQuotations cmp, list
      var i2 = i
      var minCmp = proc(a, b: MinValue): int {.closure.}=
        i2.push a
        i2.push b
        i2.unquote("<sort-cmp>", cmp)
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
        i.unquote("<linrec-predicate>", p)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          i.unquote("<linrec-true>", t)
        else:
          i.unquote("<linrec-r1>", r1)
          i.linrec(p, t, r1, r2)
          i.unquote("<linrec-r2>", r2)
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

    .symbol("dprint") do (i: In):
      var d: MinValue
      i.reqDictionary d
      for v in d.qVal:
        echo "$1: $2" % [$v.qVal[0], $v.qVal[1]]
      #i.push d

    .symbol("keys") do (i: In):
      var d: MinValue
      i.reqDictionary d
      #i.push d
      i.push i.keys(d)

    .symbol("values") do (i: In):
      var d: MinValue
      i.reqDictionary d
      #i.push d
      i.push i.values(d)

    .symbol("interpolate") do (i: In):
      var s, q: MinValue
      i.reqQuotationAndString q, s
      var strings = newSeq[string](0)
      for el in q.qVal:
        if el.isSymbol:
          i.push el
          strings.add $$i.pop
        else:
          strings.add $$el
      let res = s.strVal % strings
      i.push res.newVal

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
      let json = MINIMSYMBOLS.readFile.parseJson
      json[sym] = %op.val
      MINIMSYMBOLS.writeFile(json.pretty)

    .symbol("load-symbol") do (i: In):
      var s:MinValue
      i.reqStringLike s
      let sym = s.getString
      let json = MINIMSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      let val = i.fromJson(json[sym])
      i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val)

    .symbol("stored-symbols") do (i: In):
      var q = newSeq[MinValue](0)
      let json = MINIMSYMBOLS.readFile.parseJson
      for k,v in json.pairs:
        q.add k.newVal
      i.push q.newVal(i.scope)

    .symbol("remove-symbol") do (i: In):
      var s:MinValue
      i.reqStringLike s
      let sym = s.getString
      var json = MINIMSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      json.delete(sym)
      MINIMSYMBOLS.writeFile(json.pretty)

    .symbol("seal") do (i: In):
      var sym: MinValue 
      i.reqStringLike sym
      var s = i.scope.getSymbol(sym.getString) 
      s.sealed = true
      i.scope.setSymbol(sym.getString, s)

    # Sigils

    .sigil("'") do (i: In):
      var s: MinValue
      i.reqString s
      i.push(@[s.strVal.newSym].newVal(i.scope))

    .sigil(":") do (i: In):
      i.push("define".newSym)

    .sigil("~") do (i: In):
      i.push("delete".newSym)

    .sigil("$") do (i: In):
      i.push("getenv".newSym)

    .sigil("!") do (i: In):
      i.push("system".newSym)

    .sigil("&") do (i: In):
      i.push("run".newSym)

    .sigil("@") do (i: In):
      i.push("bind".newSym)

    .sigil("=") do (i: In):
      i.push("module".newSym)

    .sigil("^") do (i: In):
      i.push("call".newSym)

    .sigil("/") do (i: In):
      i.push("dget".newSym)

    .sigil(">") do (i: In):
      i.push("save-symbol".newSym)

    .sigil("<") do (i: In):
      i.push("load-symbol".newSym)

    .sigil("*") do (i: In):
      i.push("seal".newSym)

    .symbol(":") do (i: In):
      i.push("define".newSym)

    .symbol("!") do (i: In):
      i.push("system".newSym)

    .symbol("&") do (i: In):
      i.push("run".newSym)

    .symbol("$") do (i: In):
      i.push("getenv".newSym)

    .symbol("^") do (i: In):
      i.push("call".newSym)

    .symbol("%") do (i: In):
      i.push("interpolate".newSym)

    .symbol("'") do (i: In):
      i.push("quote".newSym)

    .symbol("->") do (i: In):
      i.push("unquote".newSym)

    #.symbol("=>") do (i: In):
    #  i.push("scope".newSym)

    .symbol("=~") do (i: In):
      i.push("regex".newSym)

    .finalize()
