import 
  critbits, 
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
    quit(vals[0].intVal.int)
   
  def.symbol("apply") do (i: In):
    let vals = i.expect("quot")
    var prog = vals[0]
    i.apply prog

  def.symbol("symbols") do (i: In):
    var q = newSeq[MinValue](0)
    var scope = i.scope
    while not scope.isNil:
      for s in scope.symbols.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal(i.scope)

  def.symbol("defined?") do (i: In):
    let vals = i.expect("'sym")
    i.push(i.scope.hasSymbol(vals[0].getString).newVal)

  def.symbol("sigils") do (i: In):
    var q = newSeq[MinValue](0)
    var scope = i.scope
    while not scope.isNil:
      for s in scope.sigils.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal(i.scope)

  def.symbol("module-symbols") do (i: In):
    let vals = i.expect("quot")
    let m = vals[0]
    var q = newSeq[MinValue](0)
    for s in m.scope.symbols.keys:
      q.add s.newVal
    i.push q.newVal(i.scope)

  def.symbol("module-sigils") do (i: In):
    let vals = i.expect("quot")
    let m = vals[0]
    var q = newSeq[MinValue](0)
    for s in m.scope.sigils.keys:
      q.add s.newVal
    i.push q.newVal(i.scope)

  def.symbol("lite?") do (i: In):
    i.push defined(lite).newVal

  def.symbol("from-json") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.push i.fromJson(s.getString.parseJson)

  def.symbol("to-json") do (i: In):
    let vals = i.expect "quot"
    let q = vals[0]
    i.push(($((%q).pretty)).newVal)

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
    if not q1.isQuotation:
      q1 = @[q1].newVal(i.scope)
    symbol = sym.getString
    if not symbol.match "^[a-zA-Z_][a-zA-Z0-9/!?+*._-]*$":
      raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[define] $1 = $2" % [symbol, $q1]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false)

  def.symbol("bind") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    if not q1.isQuotation:
      q1 = @[q1].newVal(i.scope)
    symbol = sym.getString
    info "[bind] $1 = $2" % [symbol, $q1]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1))
    if not res:
      raiseUndefined("Attempting to bind undefined symbol: " & symbol)

  def.symbol("delete") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    let res = i.scope.delSymbol(sym.getString) 
    if not res:
      raiseUndefined("Attempting to delete undefined symbol: " & sym.getString)

  def.symbol("module") do (i: In):
    let vals = i.expect("'sym", "quot")
    let name = vals[0]
    var code = vals[1]
    code.filename = i.filename
    i.dequote(code)
    info("[module] $1 ($2 symbols)" % [name.getString, $code.scope.symbols.len])
    i.scope.symbols[name.getString] = MinOperator(kind: minValOp, val: @[code].newVal(i.scope))

  def.symbol("import") do (i: In):
    var vals = i.expect("'sym")
    let rawName = vals[0]
    var name: string
    name = rawName.getString
    var op = i.scope.getSymbol(name)
    i.apply(op)
    vals = i.expect("quot")
    let mdl = vals[0]
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
  
  def.symbol("eval") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.eval s.strVal

  def.symbol("parse") do (i: In):
    let vals = i.expect("string")
    let s = vals[0]
    i.push i.parse s.strVal

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
    let vals = i.expect("quot", "quot")
    var qscope = vals[0]
    let qprog = vals[1]
    if qscope.qVal.len > 0:
      # System modules are empty quotes and don't need to be dequoted
      i.dequote(qscope)
    i.withScope(qscope):
      for v in qprog.qVal:
        i.push v

  def.symbol("publish") do (i: In):
    let vals = i.expect("quot", "'sym")
    let qscope = vals[0]
    let str = vals[1]
    let sym = str.getString
    if qscope.scope.symbols.hasKey(sym) and qscope.scope.symbols[sym].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [sym])
    let scope = i.scope
    info("[publish] Symbol: $2" % [sym])
    let op = proc(i: In) {.closure.} =
      let origscope = i.scope 
      i.scope = scope
      i.evaluating = true
      i.push sym.newSym
      i.evaluating = false
      i.scope = origscope
    qscope.scope.symbols[sym] = MinOperator(kind: minProcOp, prc: op)

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
    let vals = i.expect("'sym", "quot")
    let symbol = vals[0]
    let q = vals[1]
    let s = symbol.getString
    let origScope = i.scope
    i.scope = q.scope
    let sym = i.scope.getSymbol(s)
    i.apply(sym)
    i.scope = origScope

  def.symbol("raise") do (i: In):
    let vals = i.expect("dict")
    let err = vals[0]
    if err.dhas("error".newVal) and err.dhas("message".newVal):
      raiseRuntime("($1) $2" % [err.dget("error".newVal).getString, err.dget("message".newVal).getString], err.qVal)
    else:
      raiseInvalid("Invalid error dictionary")

  def.symbol("format-error") do (i: In):
    let vals = i.expect("dict")
    let err = vals[0]
    if err.dhas("error".newVal) and err.dhas("message".newVal):
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

  def.symbol("try") do (i: In):
    let vals = i.expect("quot")
    let prog = vals[0]
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
      raiseInvalid("Quotation must contain at least one quotation")
    try:
      i.dequote(code)
    except MinRuntimeError:
      if not hasCatch:
        return
      let e = (MinRuntimeError)getCurrentException()
      i.push e.qVal.newVal(i.scope)
      i.dequote(catch)
    except:
      if not hasCatch:
        return
      let e = getCurrentException()
      var res = newSeq[MinValue](0)
      let err = sgregex.replace($e.name, ":.+$", "")
      res.add @["error".newVal, err.newVal].newVal(i.scope)
      res.add @["message".newVal, e.msg.newVal].newVal(i.scope)
      res.add @["symbol".newVal, i.currSym].newVal(i.scope)
      res.add @["filename".newVal, i.currSym.filename.newVal].newVal(i.scope)
      res.add @["line".newVal, i.currSym.line.newVal].newVal(i.scope)
      res.add @["column".newVal, i.currSym.column.newVal].newVal(i.scope)
      i.push res.newVal(i.scope)
      i.dequote(catch)
    finally:
      if hasFinally:
        i.dequote(final)

  def.symbol("quote") do (i: In):
    let vals = i.expect("a")
    let a = vals[0]
    i.push @[a].newVal(i.scope)
  
  def.symbol("dequote") do (i: In):
    let vals = i.expect("quot")
    var q = vals[0]
    i.dequote(q)

  def.symbol("tap") do (i: In):
    let vals = i.expect("quot", "a")
    let programs = vals[0]
    var a = vals[1]
    for program in programs.qVal:
      var p = program
      i.push(a)
      i.dequote(p)
      a = i.pop
    i.push(a)

  def.symbol("tap!") do (i: In):
    let vals = i.expect("quot", "a")
    let programs = vals[0]
    var a = vals[1]
    for program in programs.qVal:
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
    if res.boolVal == true:
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
    if res.boolVal == true:
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
    if res.boolVal == false:
      i.dequote(tpath)

  # 4 (
  #   ((> 3) ("Greater than 3" put!))
  #   ((< 3) ("Smaller than 3" put!))
  #   ((true) ("Exactly 3" put!))
  # ) case
  def.symbol("case") do (i: In):
    let vals = i.expect("quot")
    var cases = vals[0]
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
      i.dequote(q)
      let res = i.pop
      if not res.isBool():
        raiseInvalid("Result of case #$1 is not a boolean value" % $k)
      if res.boolVal == true:
        var t = c.qVal[1]
        i.dequote(t)
        break

  # Loops

  def.symbol("foreach") do (i: In):
    let vals = i.expect("quot", "quot")
    var prog = vals[0]
    var list = vals[1]
    for litem in list.qVal:
      i.push litem
      i.dequote(prog)
  
  def.symbol("times") do (i: In):
    let vals = i.expect("int", "quot")
    var t = vals[0]
    var prog = vals[1]
    if t.intVal < 1:
      raiseInvalid("A non-zero natural number is required")
    for c in 1..t.intVal:
      i.dequote(prog)
  
  def.symbol("while") do (i: In):
    let vals = i.expect("quot", "quot")
    var d = vals[0]
    var b = vals[1]
    for e in b.qVal:
      i.push e
    i.dequote(b)
    var check = i.pop
    while check.isBool and check.boolVal == true:
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
      if check.isBool and check.boolVal == true:
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
    json[sym] = %op.val
    MINSYMBOLS.writeFile(json.pretty)

  def.symbol("load-symbol") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let sym = s.getString
    let json = MINSYMBOLS.readFile.parseJson
    if not json.hasKey(sym):
      raiseUndefined("Symbol '$1' not found." % sym)
    let val = i.fromJson(json[sym])
    i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val)

  def.symbol("stored-symbols") do (i: In):
    var q = newSeq[MinValue](0)
    let json = MINSYMBOLS.readFile.parseJson
    for k,v in json.pairs:
      q.add k.newVal
    i.push q.newVal(i.scope)

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
    i.push @[m].newVal(i.scope)
    i.push s
    i.push "bind".newSym

  def.symbol("quote-define") do (i: In):
    let vals = i.expect("string", "a")
    let s = vals[0]
    let m = vals[1]
    i.push @[m].newVal(i.scope)
    i.push s
    i.push "define".newSym


  def.symbol("args") do (i: In):
    var args = newSeq[MinValue](0)
    for kind, key, val in getopt():
      case kind:
        of cmdArgument:
          args.add key.newVal
        else:
          discard
    i.push args.newVal(i.scope)

  def.symbol("opts") do (i: In):
    var opts = newVal(newSeq[MinValue](0), i.scope) 
    for kind, key, val in getopt():
      case kind:
        of cmdLongOption, cmdShortOption:
          if val == "":
            opts = i.dset(opts, key.newVal, true.newVal)
          else:
            opts = i.dset(opts, key.newVal, val.newVal)
        else:
          discard
    i.push opts

  def.symbol("raw-args") do (i: In):
    var args = newSeq[MinValue](0)
    for par in commandLineParams():
        args.add par.newVal
    i.push args.newVal(i.scope)

  def.symbol("expect") do (i: In):
    var q: MinValue
    i.reqQuotationOfSymbols q
    i.push(i.expect(q.qVal.mapIt(it.getString())).reversed.newVal(i.scope))

  # Converters

  def.symbol("string") do (i: In):
    let s = i.pop
    i.push(($$s).newVal)

  def.symbol("bool") do (i: In):
    let v = i.pop
    let strcheck = (v.isString and (v.getString == "false" or v.getString == ""))
    let intcheck = v.isInt and v.intVal == 0
    let floatcheck = v.isFloat and v.floatVal == 0
    let boolcheck = v.isBool and v.boolVal == false
    let quotcheck = v.isQuotation and v.qVal.len == 0
    if strcheck or intcheck or floatcheck or boolcheck or quotcheck:
      i.push false.newVal
    else:
      i.push true.newVal

  def.symbol("int") do (i: In):
    let s = i.pop
    if s.isString:
      i.push s.getString.parseInt.newVal
    elif s.isFloat:
      i.push s.floatVal.int.newVal
    elif s.isInt:
      i.push s
    elif s.isBool:
      if s.boolVal == true:
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
      i.push s.intVal.float.newVal
    elif s.isFloat:
      i.push s
    elif s.isBool:
      if s.boolVal == true:
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
    i.push(@[s.strVal.newSym].newVal(i.scope))

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
