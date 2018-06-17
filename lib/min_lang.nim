import 
  critbits, 
  tables,
  strutils, 
  sequtils,
  parseopt,
  algorithm,
  json,
  os, 
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
  let def = i.scope
  def.symbol("exit") do (i: In):
    let vals = i.expect("int")
    quit(vals[0].getInt)
   
  def.symbol("apply") do (i: In):
    let vals = i.expect("quot")
    var prog = vals[0]
    i.apply prog

  def.symbol("symbols") do (i: In):
    var q = newJArray()
    var scope = i.scope
    while not scope.isNil:
      for s in scope.symbols.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q

  def.symbol("defined?") do (i: In):
    let vals = i.expect("'sym")
    i.push(i.scope.hasSymbol(vals[0].getString).newVal)

  def.symbol("sigils") do (i: In):
    var q = newJArray()
    var scope = i.scope
    while not scope.isNil:
      for s in scope.sigils.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q

  def.symbol("scope-symbols") do (i: In):
    #TODO Review
    discard
    #let vals = i.expect("dict")
    #let m = vals[0]
    #var q = newJArray()
    #for s in m.scope.symbols.keys:
    #  q.add s.newVal
    #i.push q

  def.symbol("scope-sigils") do (i: In):
    #TODO Review
    discard
    #let vals = i.expect("dict")
    #let m = vals[0]
    #var q = newJArray
    #for s in m.scope.sigils.keys:
    #  q.add s.newVal
    #i.push q

  def.symbol("lite?") do (i: In):
    i.push defined(lite).newVal

  def.symbol("from-json") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.push s.getString.parseJson

  def.symbol("from-json-file") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.push s.getString.parseFile

  def.symbol("to-json") do (i: In):
    let vals = i.expect "a"
    let q = vals[0]
    i.push(($((q).pretty)).newVal)

  def.symbol("to-json-file") do (i: In):
    let vals = i.expect("'sym", "a")
    let f = vals[0]
    let q = vals[1]
    f.getString.writeFile($((q).pretty))

  def.symbol("loglevel") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    var str = s.getString
    echo "Log level: ", setLogLevel(str)

  def.symbol("loglevel?") do (i: In):
    echo "Log level: ", getLogLevel()

  # Language constructs

  def.symbol("define") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    var isQuot = true
    if not q1.isQuotation:
      q1 = @[q1].newVal
      isQuot = false
    symbol = sym.getString
    if not symbol.match "^[a-zA-Z_][a-zA-Z0-9/!?+*._-]*$":
      raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[define] $1 = $2" % [symbol, q1.str]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false, quotation: isQuot)

  def.symbol("bind") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    var isQuot = true
    if not q1.isQuotation:
      q1 = @[q1].newVal
      isQuot = false
    symbol = sym.getString
    info "[bind] $1 = $2" % [symbol, q1.str]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1, quotation: isQuot))
    if not res:
      raiseUndefined("Attempting to bind undefined symbol: " & symbol)

  def.symbol("delete") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    let res = i.scope.delSymbol(sym.getString) 
    if not res:
      raiseUndefined("Attempting to delete undefined symbol: " & sym.getString)

  def.symbol("module") do (i: In):
    let vals = i.expect("'sym", "dict")
    let name = vals[0]
    var code = vals[1]
    code[";type"] = %"module"
    #code.filename = i.filename
    info("[module] $1 ($2 symbols)" % [name.getString, $toSeq(code.getFields.keys).len])
    i.scope.symbols[name.getString] = MinOperator(kind: minValOp, val: code)

  def.symbol("import") do (i: In):
    var vals = i.expect("'sym")
    let rawName = vals[0]
    var name: string
    name = rawName.getString
    var op = i.scope.getSymbol(name)
    i.apply(op)
    vals = i.expect("dict:module|dict:native-module")
    let mref = vals[0]
    if mref.isNativeModule:
      if not NativeModules.contains(name):
        raiseUndefined("Undefined native module: " & name)
      let mdl = NativeModules[name]  
      info("[import] Importing: $1 ($2 symbols, $3 sigils)" % [name, $mdl.symbols.len, $mdl.sigils.len])
      for sig, val in mdl.sigils.pairs:
        if i.scope.sigils.hasKey(sig) and i.scope.sigils[sig].sealed:
          raiseUndefined("Attempting to redefine sealed sigil '$1'" % [sig])
        i.debug "[import] $1" % [sig]
        i.scope.sigils[sig] = val
      for sym, val in mdl.symbols.pairs:
        if i.scope.symbols.hasKey(sym) and i.scope.symbols[sym].sealed:
          raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
        i.debug "[import] $1" % [sym]
        i.scope.symbols[sym] = val
    else:
      info("[import] Importing: $1 ($2 symbols)" % [name, $(toSeq(mref.pairs).len)])
      for pair in mref.pairs:
        var sym = pair.key
        if i.scope.symbols.hasKey(sym) and i.scope.symbols[sym].sealed:
          raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
        i.debug "[import] $1" % [sym]
        i.scope.symbols[sym] = MinOperator(kind: minValOp, val: pair.val)
  
  def.symbol("eval") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.eval s.getStr

  def.symbol("parse") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.push i.parse s.getStr

  def.symbol("load") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    var file = s.getString
    if not file.endsWith(".min"):
      file = file & ".min"
    file = i.pwd.joinPath(file)
    info("[load] File: ", file)
    if not file.fileExists:
      raiseInvalid("File '$1' does not exist." % file)
    i.load file

  def.symbol("read") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    var file = s.getString
    if not file.endsWith(".min"):
      file = file & ".min"
    info("[read] File: ", file)
    if not file.fileExists:
      raiseInvalid("File '$1' does not exist." % file)
    i.push i.read file

  def.symbol("with") do (i: In):
    let vals = i.expect("dict:module|dict:native-module", "quot")
    var mdl = vals[0]
    let qprog = vals[1]
    i.withModuleScope(mdl):
      for v in qprog.elems:
        i.push v

  def.symbol("publish") do (i: In):
    let vals = i.expect("dict:module|dict:native-module", "'sym")
    var d = vals[0]
    let str = vals[1]
    let sym = str.getString
    if d.isNativeModule:
      var mdl = NativeModules[d.name]
      if mdl.symbols.hasKey(sym) and mdl.symbols[sym].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
      let scope = i.scope
      info("[publish] Symbol: $1" % [sym])
      let op = proc(i: In) {.closure.} =
        let origscope = i.scope 
        i.scope = scope
        i.evaluating = true
        i.push sym.newSym
        i.evaluating = false
        i.scope = origscope
      mdl.symbols[sym] = MinOperator(kind: minProcOp, prc: op)
    else:
      if d.hasKey(sym) and d[sym].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
      let val = i.scope.getSymbol(sym)
      if val.kind == minValOp:
        d[sym] = val.val
      else:
        raiseUndefined("Unable to publish native symbol:" & sym)

  def.symbol("source") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let str = s.getString
    let sym = i.scope.getSymbol(str)
    if sym.kind == minValOp:
      i.push sym.val
    else:
      raiseInvalid("No source available for native symbol '$1'." % str)

  def.symbol("call") do (i: In):
    let vals = i.expect("'sym", "dict:module|dict:native-module")
    let symbol = vals[0]
    let d = vals[1]
    let sym = symbol.getString
    if d.isNativeModule:
      let mdl = NativeModules[d.name]
      if not mdl.symbols.hasKey(sym):
        raiseUndefined("Symbol '$1' not defined in specified module." % [sym])
      let origScope = i.scope
      i.scope = mdl
      let sym = i.scope.getSymbol(sym)
      i.apply(sym)
      i.scope = origScope
    else:
      if not d.hasKey(sym):
        raiseUndefined("Symbol not defined in dictionary: " & sym)
      i.withModuleScope(d):
        i.push(d[sym])

  def.symbol("set-type") do (i: In):
    let vals = i.expect("'sym", "dict")
    let symbol = vals[0]
    var d = vals[1]
    d[";type"] = %symbol.getString
    i.push d

  def.symbol("raise") do (i: In):
    let vals = i.expect("dict")
    let err = vals[0]
    if err.hasKey("error") and err.hasKey("message"):
      raiseRuntime("($1) $2" % [err["error"].getString, err["message"].getString], err)
    else:
      raiseInvalid("Invalid error dictionary")

  def.symbol("format-error") do (i: In):
    let vals = i.expect("dict:error")
    let err = vals[0]
    if err.hasKey("error") and err.haskey("message"):
      var msg: string
      var list = newJArray()
      list.add err["message"]
      if err.hasKey("symbol"):
        list.add err["symbol"]
      if err.hasKey("filename"):
        list.add err["filename"]
      if err.hasKey("line"):
        list.add err["line"]
      if err.hasKey("column"):
        list.add err["column"]
      if list.len <= 1:
        msg = "$1" % $$list[0]
      else:
        msg = "$3($4,$5) `$2`: $1" % [$$list[0], $$list[1], $$list[2], $$list[3], $$list[4]]
      i.push msg.newVal
    else:
      raiseInvalid("Invalid error dictionary")

  def.symbol("try") do (i: In):
    let vals = i.expect("quot")
    let prog = vals[0]
    if prog.elems.len == 0:
      raiseInvalid("Quotation must contain at least one element")
    var code = prog.elems[0]
    var final, catch: MinValue
    var hasFinally = false
    var hasCatch = false
    if prog.elems.len > 1:
      catch = prog.elems[1]
      hasCatch = true
    if prog.elems.len > 2:
      final = prog.elems[2]
      hasFinally = true
    if (not code.isQuotation) or (hasCatch and not catch.isQuotation) or (hasFinally and not final.isQuotation):
      raiseInvalid("Quotation must contain at least one quotation")
    try:
      i.dequote(code)
    except MinRuntimeError:
      if not hasCatch:
        return
      let e = (MinRuntimeError)getCurrentException()
      i.push e.data
      i.dequote(catch)
    except:
      if not hasCatch:
        return
      let e = getCurrentException()
      var res = newJObject()
      let err = sgregex.replace($e.name, ":.+$", "")
      res[";type"] = %"error"
      res["error"] = %err
      res["message"] = %e.msg
      res["symbol"] = i.currSym
      #TODO Review
      #res["filename"] = %i.currSym.filename
      #res["line"] = %i.currSym.line
      #res["column"] = %i.currSym.column
      i.push res
      i.dequote(catch)
    finally:
      if hasFinally:
        i.dequote(final)

  def.symbol("quote") do (i: In):
    let vals = i.expect("a")
    let q = newJArray()
    q.add vals[0]
    i.push q
  
  def.symbol("dequote") do (i: In):
    let vals = i.expect("quot")
    var q = vals[0]
    i.dequote(q)

  def.symbol("tap") do (i: In):
    let vals = i.expect("quot", "a")
    let programs = vals[0]
    var a = vals[1]
    for program in programs.elems:
      var p = program
      i.push(a)
      i.dequote(p)
      a = i.pop
    i.push(a)

  def.symbol("tap!") do (i: In):
    let vals = i.expect("quot", "a")
    let programs = vals[0]
    var a = vals[1]
    for program in programs.elems:
      var p = program
      i.push(a)
      i.dequote(p)
      a = i.pop
  
  # Conditionals

  def.symbol("if") do (i: In):
    let vals = i.expect("quot", "quot", "quot")
    var fpath = vals[0]
    var tpath = vals[1]
    var check = vals[2]
    var stack = i.stack
    i.dequote(check)
    let res = i.pop
    i.stack = stack
    if not res.isBool:
      raiseInvalid("Result of check is not a boolean value")
    if res.getBool == true:
      i.dequote(tpath)
    else:
      i.dequote(fpath)

  def.symbol("when") do (i: In):
    let vals = i.expect("quot", "quot")
    var tpath = vals[0]
    var check = vals[1]
    var stack = i.stack
    i.dequote(check)
    let res = i.pop
    i.stack = stack
    if not res.isBool:
      raiseInvalid("Result of check is not a boolean value")
    if res.getBool == true:
      i.dequote(tpath)

  def.symbol("unless") do (i: In):
    let vals = i.expect("quot", "quot")
    var tpath = vals[0]
    var check = vals[1]
    var stack = i.stack
    i.dequote(check)
    let res = i.pop
    i.stack = stack
    if not res.isBool:
      raiseInvalid("Result of check is not a boolean value")
    if res.getBool == false:
      i.dequote(tpath)

  # 4 (
  #   ((> 3) ("Greater than 3" put!))
  #   ((< 3) ("Smaller than 3" put!))
  #   ((true) ("Exactly 3" put!))
  # ) case
  def.symbol("case") do (i: In):
    let vals = i.expect("quot")
    var cases = vals[0]
    if cases.elems.len == 0:
      raiseInvalid("Empty case operator")
    var k = 0
    let stack = i.stack
    for c in cases.elems:
      i.stack = stack
      if not c.isQuotation:
        raiseInvalid("A quotation of quotations is required")
      k.inc
      if c.elems.len != 2 or not c.elems[0].isQuotation or not c.elems[1].isQuotation:
        raiseInvalid("Inner quotations in case operator must contain two quotations")
      var q = c.elems[0]
      i.dequote(q)
      let res = i.pop
      if not res.isBool():
        raiseInvalid("Result of case #$1 is not a boolean value" % $k)
      if res.getBool == true:
        var t = c.elems[1]
        i.dequote(t)
        break

  # Loops

  def.symbol("foreach") do (i: In):
    let vals = i.expect("quot", "quot")
    var prog = vals[0]
    var list = vals[1]
    for litem in list.elems:
      i.push litem
      i.dequote(prog)
  
  def.symbol("times") do (i: In):
    let vals = i.expect("int", "quot")
    var t = vals[0]
    var prog = vals[1]
    if t.getInt < 1:
      raiseInvalid("A non-zero natural number is required")
    for c in 1..t.getInt:
      i.dequote(prog)
  
  def.symbol("while") do (i: In):
    let vals = i.expect("quot", "quot")
    var d = vals[0]
    var b = vals[1]
    for e in b.elems:
      i.push e
    i.dequote(b)
    var check = i.pop
    while check.isBool and check.getBool == true:
      i.dequote(d)
      i.dequote(b)
      check = i.pop
    discard i.pop

  # Other
  
  def.symbol("linrec") do (i: In):
    let vals = i.expect("quot", "quot", "quot", "quot")
    var r2 = vals[0]
    var r1 = vals[1]
    var t = vals[2]
    var p = vals[3]
    proc linrec(i: In, p, t, r1, r2: var MinValue) =
      i.dequote(p)
      var check = i.pop
      if check.isBool and check.getBool == true:
        i.dequote(t)
      else:
        i.dequote(r1)
        i.linrec(p, t, r1, r2)
        i.dequote(r2)
    i.linrec(p, t, r1, r2)

  def.symbol("version") do (i: In):
    i.push version.newVal

  # Save/load symbols
  
  def.symbol("save-symbol") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let sym = s.getString
    let op = i.scope.getSymbol(sym)
    if op.kind == minProcOp:
      raiseInvalid("Symbol '$1' cannot be serialized." % sym)
    let json = MINSYMBOLS.readFile.parseJson
    json[sym] = op.val
    MINSYMBOLS.writeFile(json.pretty)

  def.symbol("load-symbol") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let sym = s.getString
    let json = MINSYMBOLS.readFile.parseJson
    if not json.hasKey(sym):
      raiseUndefined("Symbol '$1' not found." % sym)
    let val = json[sym]
    i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val, quotation: true)

  def.symbol("stored-symbols") do (i: In):
    var q = newJArray()
    let json = MINSYMBOLS.readFile.parseJson
    for k,v in json.pairs:
      q.add %k
    i.push q

  def.symbol("remove-symbol") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let sym = s.getString
    var json = MINSYMBOLS.readFile.parseJson
    if not json.hasKey(sym):
      raiseUndefined("Symbol '$1' not found." % sym)
    json.delete(sym)
    MINSYMBOLS.writeFile(json.pretty)

  def.symbol("seal") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    var s = i.scope.getSymbol(sym.getString) 
    s.sealed = true
    i.scope.setSymbol(sym.getString, s)

  def.symbol("unseal") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    var s = i.scope.getSymbol(sym.getString) 
    s.sealed = false
    i.scope.setSymbol(sym.getString, s, true)

  def.symbol("quote-bind") do (i: In):
    let vals = i.expect("string", "a")
    let s = vals[0]
    let m = vals[1]
    var q = newJArray()
    q.add m
    i.push q
    i.push s
    i.push "bind".newSym

  def.symbol("quote-define") do (i: In):
    let vals = i.expect("string", "a")
    let s = vals[0]
    let m = vals[1]
    var q = newJArray()
    q.add m
    i.push q
    i.push s
    i.push "define".newSym


  def.symbol("args") do (i: In):
    var args = newJArray()
    for kind, key, val in getopt():
      case kind:
        of cmdArgument:
          args.add %key
        else:
          discard
    i.push args

  def.symbol("opts") do (i: In):
    var opts = newJObject()
    for kind, key, val in getopt():
      case kind:
        of cmdLongOption, cmdShortOption:
          if val == "":
            opts[key] = %true
          else:
            opts[key] = %val
        else:
          discard
    i.push opts

  def.symbol("raw-args") do (i: In):
    var args = newJArray()
    for par in commandLineParams():
        args.add %par
    i.push args

  def.symbol("expect") do (i: In):
    var q: MinValue
    i.reqQuotationOfSymbols q
    #i.push(i.expect(q.elems.mapIt(it.getString())).reversed.newVal(i.scope))
    let res = newJArray()
    res.elems = i.expect(q.elems.mapIt(it.getString())).reversed
    i.push res

  # Converters

  def.symbol("string") do (i: In):
    let s = i.pop
    i.push(($$s).newVal)

  def.symbol("bool") do (i: In):
    let v = i.pop
    let strcheck = (v.isString and (v.getString == "false" or v.getString == ""))
    let intcheck = v.isInt and v.getInt == 0
    let floatcheck = v.isFloat and v.getFloat == 0
    let boolcheck = v.isBool and v.getBool == false
    let quotcheck = v.isQuotation and v.elems.len == 0
    if strcheck or intcheck or floatcheck or boolcheck or quotcheck:
      i.push false.newVal
    else:
      i.push true.newVal

  def.symbol("int") do (i: In):
    let s = i.pop
    if s.isString:
      i.push s.getString.parseInt.newVal
    elif s.isFloat:
      i.push s.getFloat.int.newVal
    elif s.isInt:
      i.push s
    elif s.isBool:
      if s.getBool == true:
        i.push 1.int.newVal
      else:
        i.push 0.int.newVal
    else:
      raiseInvalid("Cannot convert a quotation to an integer.")

  def.symbol("float") do (i: In):
    let s = i.pop
    if s.isString:
      i.push s.getString.parseFloat.newVal
    elif s.isInt:
      i.push s.getInt.float.newVal
    elif s.isFloat:
      i.push s
    elif s.isBool:
      if s.getBool == true:
        i.push 1.float.newVal
      else:
        i.push 0.float.newVal
    else:
      raiseInvalid("Cannot convert a quotation to float.")

  def.symbol("prompt") do (i: In):
    i.eval(""""[$1]$$ " (.) => %""")

  # Sigils

  def.sigil("'") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    var res = newJArray()
    res.add s.getStr.newSym
    i.push res

  def.sigil(":") do (i: In):
    i.push("define".newSym)

  def.sigil("~") do (i: In):
    i.push("delete".newSym)

  def.sigil("@") do (i: In):
    i.push("bind".newSym)

  def.sigil("+") do (i: In):
    i.push("module".newSym)

  def.sigil("^") do (i: In):
    i.push("call".newSym)

  def.sigil(">") do (i: In):
    i.push("save-symbol".newSym)

  def.sigil("<") do (i: In):
    i.push("load-symbol".newSym)

  def.sigil("#") do (i: In):
    i.push("quote-bind".newSym)

  def.sigil("=") do (i: In):
    i.push("quote-define".newSym)

  # Shorthand symbol aliases

  def.symbol("#") do (i: In):
    i.push("quote-bind".newSym)

  def.symbol("=") do (i: In):
    i.push("quote-define".newSym)

  def.symbol(":") do (i: In):
    i.push("define".newSym)

  def.symbol("@") do (i: In):
    i.push("bind".newSym)

  def.symbol("^") do (i: In):
    i.push("call".newSym)

  def.symbol("'") do (i: In):
    i.push("quote".newSym)

  def.symbol("->") do (i: In):
    i.push("dequote".newSym)

  def.symbol("=>") do (i: In):
    i.push("apply".newSym)

  def.finalize("ROOT")
