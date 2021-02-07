import 
  critbits, 
  strutils, 
  sequtils,
  json,
  parseopt,
  algorithm
when defined(mini):
  import
    rdstdin,
    ../core/minilogger
else:
  import 
    os,
    logging,
    ../core/baseutils,
    ../packages/niftylogger,
    ../packages/nimline/nimline,
    ../packages/nim-sgregex/sgregex
import 
  ../core/env,
  ../core/meta,
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../core/scope

proc lang_module*(i: In) =
  let def = i.scope
  
  const HELPFILE = "../../help.json".slurp
  let HELP = HELPFILE.parseJson

  when not defined(mini):
  
    def.symbol("from-json") do (i: In) {.gcsafe.}:
      let vals = i.expect("str")
      let s = vals[0]
      i.push i.fromJson(s.getString.parseJson)
      
    def.symbol("to-json") do (i: In):
      let vals = i.expect "a"
      let q = vals[0]
      i.push(($((i%q).pretty)).newVal)
  
    # Save/load symbols
  
    def.symbol("save-symbol") do (i: In) {.gcsafe.}:
      let vals = i.expect("'sym")
      let s = vals[0]
      let sym = s.getString
      let op = i.scope.getSymbol(sym)
      if op.kind == minProcOp:
        raiseInvalid("Symbol '$1' cannot be serialized." % sym)
      let json = MINSYMBOLS.readFile.parseJson
      json[sym] = i%op.val
      MINSYMBOLS.writeFile(json.pretty)

    def.symbol("load-symbol") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0]
      let sym = s.getString
      let json = MINSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      let val = i.fromJson(json[sym])
      i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val, quotation: true)

    def.symbol("saved-symbols") do (i: In):
      var q = newSeq[MinValue](0)
      let json = MINSYMBOLS.readFile.parseJson
      for k,v in json.pairs:
        q.add k.newVal
      i.push q.newVal

    def.symbol("remove-symbol") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0]
      let sym = s.getString
      var json = MINSYMBOLS.readFile.parseJson
      if not json.hasKey(sym):
        raiseUndefined("Symbol '$1' not found." % sym)
      json.delete(sym)
      MINSYMBOLS.writeFile(json.pretty)

    def.symbol("load") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0]
      var file = s.getString
      if not file.endsWith(".min"):
        file = file & ".min"
      info("[load] File: ", file)
      let f = simplifyPath(i.filename, file)
      if MINCOMPILED and COMPILEDMINFILES.hasKey(f):
          var i2 = i.copy(f)
          i2.withScope():
            COMPILEDMINFILES[f](i2)
            i = i2.copy(i.filename)
          return
      else:
        if not f.fileExists:
         raiseInvalid("File '$1' does not exist." % file)
      i.load f

    def.symbol("require") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0]
      var file = s.getString
      if not file.endsWith(".min"):
        file = file & ".min"
      info("[require] File: ", file)
      let f = simplifyPath(i.filename, file)
      if MINCOMPILED and COMPILEDMINFILES.hasKey(f):
          var i2 = i.copy(f)
          i2.withScope():
            var mdl: MinValue
            if not CACHEDMODULES.hasKey(f):
              COMPILEDMINFILES[f](i2)
              CACHEDMODULES[f] = newDict(i2.scope)
              CACHEDMODULES[f].objType = "module"
            mdl = CACHEDMODULES[f]
            for key, value in i2.scope.symbols.pairs:
              mdl.scope.symbols[key] = value
            i.push(mdl)
      else:
        if not f.fileExists:
          raiseInvalid("File '$1' does not exist." % file)
        i.push i.require(f)

    def.symbol("raw-args") do (i: In):
      var args = newSeq[MinValue](0)
      for par in commandLineParams():
          args.add par.newVal
      i.push args.newVal

  def.symbol("with") do (i: In):
    let vals = i.expect("dict", "quot")
    var qscope = vals[0]
    var qprog = vals[1]
    i.withDictScope(qscope.scope):
      for v in qprog.qVal:
        i.push v

  def.symbol("publish") do (i: In):
    let vals = i.expect("dict", "'sym")
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
      i.pushSym sym
      i.evaluating = false
      i.scope = origscope
    qscope.scope.symbols[sym] = MinOperator(kind: minProcOp, prc: op)

  ### End of symbols not present in minimin
  
  def.symbol("operator") do (i: In):
    let vals = i.expect("quot");
    let q = vals[0]
    if q.qVal.len != 4:
      raiseInvalid("Invalid operator definition")
    let tv = q.qVal[0]
    let t = tv.symVal
    let nv = q.qVal[1]
    if not tv.isSymbol or (not ["symbol", "sigil",  "typeclass", "constructor"].contains(t)):
      raiseInvalid("Incorrect operator type specified (it must be 'symbol', 'sigil', 'constructor', or 'typeclass' - found '$#')" % tv.symVal)
    
    if not nv.isSymbol:
      raiseInvalid("Operator name must be a symbol")
    var n = nv.symVal
    when not defined(mini):
      if not n.match(USER_SYMBOL_REGEX):
        raiseInvalid("Operator name must not contain invalid characters")
    if t == "typeclass":
      n = "typeclass:"&n
    # Validate signature
    let sv = q.qVal[2]
    if not sv.isQuotation:
      raiseInvalid("Signature must be a quotation")
    elif sv.qVal.len == 0:
      raiseInvalid("No signature specified")
    elif sv.qVal.len == 1 and sv.qVal[0] != "==>".newSym:
      raiseInvalid("Invalid signature")
    elif sv.qVal.len mod 2 == 0:
      raiseInvalid("Invalid signature")
    var c = 0
    # Process signature
    let docSig = $sv
    var inExpects= newSeq[string](0)
    var inVars = newSeq[string](0)
    var outExpects= newSeq[string](0)
    var outVars = newSeq[string](0)
    var rawOutVars = newSeq[string](0)
    var generics: CritBitTree[string]
    var origGenerics: CritBitTree[string]
    var o = false
    for vv in sv.qVal:
      if not vv.isSymbol and not vv.isQuotation:
        raiseInvalid("Signature must be a quotation of symbols/quotations")
      var v: string
      var check = c mod 2 == 0
      if o:
        check = c mod 2 != 0
      if vv.isQuotation:
        if vv.qVal.len != 2 or not vv.qVal[0].isSymbol or not vv.qVal[1].isSymbol:
          raiseInvalid("Generic quotation must contain exactly two symbols")
        let t = vv.qVal[0].getString
        let g = vv.qVal[1].getString
        if not i.validType(t):
          raiseInvalid("Invalid type '$#' in generic in signature at position $#" % [$t, $(c+1)])
        if g[0] != ':' and g[0] != '^':
          raiseInvalid("No mapping symbol specified in generic in signature at position $#" % $(c+1))
        v = g[1..g.len-1]
        generics[v] = t
      else:
        v = vv.symVal
      if check:
        if v == "==>":
          o = true
        elif not i.validType(v) and not generics.hasKey(v):
          raiseInvalid("Invalid type '$#' specified in signature at position $#" % [v, $(c+1)])
        else:
          if o:
            if tv.symVal == "typeclass" and (outExpects.len > 0 or v != "bool"):
              raiseInvalid("typeclasses can only have one boolean output value")
            if tv.symVal == "constructor" and (outExpects.len > 0 or v != "dict"):
              raiseInvalid("constructors can only have one dictionary output value")
            outExpects.add v
          else:
            if tv.symVal == "typeclass" and inExpects.len > 0:
              raiseInvalid("typeclasses can only have one input value")
            inExpects.add v
      else:
        if v[0] != ':' and v[0] != '^':
          raiseInvalid("No capturing symbol specified in signature at position $#" % $(c+1))
        else:
          if o:
            if v[0] == '^' and outExpects[outExpects.len-1] != "quot":
              raiseInvalid("Only quotations can be captured to a lambda, found $# instead at position $#" % [outExpects[outExpects.len-1], $(c+1)])
            rawOutVars.add v
            outVars.add v[1..v.len-1]
          else:
            if v[0] == '^':
              raiseInvalid("A lambda capturing symbol was specified in signature at position $#. Lambda capturing symbols are only allowed for output values" % $(c+1))
            inVars.add v[1..v.len-1]
      c.inc()
    if not o:
      raiseInvalid("No output specified in signature")
    origGenerics = deepCopy(generics)
    # Process body
    var bv = q.qVal[3]
    if not bv.isQuotation:
      raiseInvalid("Body must be a quotation")
    inExpects.reverse
    inVars.reverse
    var p: MinOperatorProc = proc (i: In) =
      var inVals: seq[MinValue]
      try: 
        inVals = i.expect(inExpects, generics)
      except:
        generics = origGenerics
        raise
      i.withScope():
        # Inject variables for mapped inputs
        for k in 0..inVars.len-1:
          var iv = inVals[k]
          if iv.isQuotation:
            iv = @[iv].newVal
          i.scope.symbols[inVars[k]] = MinOperator(kind: minValOp, sealed: false, val: iv, quotation: inVals[k].isQuotation)
        # Inject variables for mapped outputs
        for k in 0..outVars.len-1:
          i.scope.symbols[outVars[k]] = MinOperator(kind: minValOp, sealed: false, val: @[newNull()].newVal, quotation: true)
        # Actually execute the body of the operator
        var endSnapshot: seq[MinValue]
        var snapShot: seq[MinValue]
        try:
          snapshot = deepCopy(i.stack)
          i.dequote bv
          endSnapshot = i.stack
          let d= snapshot.diff(endSnapshot)
          if d.len > 0 :
            raiseInvalid("Operator '$#' is polluting the stack -- $#" % [n, $d.newVal])
        except MinReturnException:
          discard
        # Validate output
        for k in 0..outVars.len-1:
          var x = i.scope.symbols[outVars[k]].val
          if rawOutVars[k][0] == ':':
            x = x.qVal[0]
          if t == "constructor":
            x.objType = n
          let o = outExpects[k]
          var r = false;
          if o.contains("|"):
            let types = o.split("|")
            for ut in types:
              if i.validate(x, ut, generics):
                r = true
                break
          else:
            r = i.validate(x, o, generics)
          if not r:
            var tp = o
            if generics.hasKey(o):
              tp = generics[o]
              generics = origGenerics
            raiseInvalid("Invalid value for output symbol '$#'. Expected $#, found $#" % [outVars[k], tp, $x])
          # Push output on stack
          i.pushSym outVars[k]
      generics = origGenerics
    # Define symbol/sigil
    var doc = newJObject()
    doc["name"] = %n
    doc["kind"] = %t
    doc["signature"] = %docSig
    doc["description"] = %i.currSym.docComment.strip 
    if ["symbol", "typeclass", "constructor"].contains(t):
      if i.scope.symbols.hasKey(n) and i.scope.symbols[n].sealed:
        raiseUndefined("Attempting to redefine sealed symbol '$1'" % [n])
      i.scope.symbols[n] = MinOperator(kind: minProcOp, prc: p, sealed: false, doc: doc)
    else:
      if i.scope.sigils.hasKey(n) and i.scope.sigils[n].sealed:
        raiseUndefined("Attempting to redefine sealed sigil '$1'" % [n])
      i.scope.sigils[n] = MinOperator(kind: minProcOp, prc: p, sealed: true, doc: doc)

  def.symbol("expect-empty-stack") do (i: In):
    let l = i.stack.len
    if l != 0:
      raiseInvalid("Expected empty stack, found $# elements instead" % $l)

  def.symbol("exit") do (i: In):
    let vals = i.expect("int")
    quit(vals[0].intVal.int)

  def.symbol("puts") do (i: In):
    let a = i.peek
    echo $$a
  
  def.symbol("gets") do (i: In) {.gcsafe.}:
    when defined(mini):
      i.push readLineFromStdin("").newVal 
    else:
      var ed = initEditor()
      i.push ed.readLine().newVal
    
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
    i.push q.newVal

  def.symbol("defined-symbol?") do (i: In):
    let vals = i.expect("'sym")
    i.push(i.scope.hasSymbol(vals[0].getString).newVal)

  def.symbol("defined-sigil?") do (i: In):
    let vals = i.expect("'sym")
    i.push(i.scope.hasSigil(vals[0].getString).newVal)
  
  def.symbol("sealed-symbol?") do (i: In):
    let vals = i.expect("'sym")
    i.push i.scope.getSymbol(vals[0].getString).sealed.newVal
  
  def.symbol("sealed-sigil?") do (i: In):
    let vals = i.expect("'sym")
    i.push i.scope.getSigil(vals[0].getString).sealed.newVal
  
  def.symbol("sigils") do (i: In):
    var q = newSeq[MinValue](0)
    var scope = i.scope
    while not scope.isNil:
      for s in scope.sigils.keys:
        q.add s.newVal
      scope = scope.parent
    i.push q.newVal

  def.symbol("scope-symbols") do (i: In):
    let vals = i.expect("dict")
    let m = vals[0]
    var q = newSeq[MinValue](0)
    for s in m.scope.symbols.keys:
      q.add s.newVal
    i.push q.newVal

  def.symbol("scope-sigils") do (i: In):
    let vals = i.expect("dict")
    let m = vals[0]
    var q = newSeq[MinValue](0)
    for s in m.scope.sigils.keys:
      q.add s.newVal
    i.push q.newVal

  def.symbol("lite?") do (i: In):
    i.push defined(lite).newVal

  def.symbol("mini?") do (i: In):
    i.push defined(mini).newVal

  def.symbol("from-yaml") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    try:
      var dict = newDict(i.scope)
      let lines = s.strVal.split("\n")
      for line in lines:
        let pair = line.split(":")
        if pair.len == 1 and pair[0].len == 0:
          continue
        i.dset(dict, pair[0].strip, pair[1].strip.newVal)
      i.push(dict)
    except:
      raiseInvalid("Invalid/unsupported YAML object (only dictionaries with string values are supported)")

  def.symbol("to-yaml") do (i: In):
    let vals = i.expect "a"
    let a = vals[0]
    let err = "YAML conversion is only supported from dictionaries with string values"
    if a.kind != minDictionary:
      raiseInvalid(err)
    var yaml = ""
    try:
      for key in i.keys(a).qVal:
        let value = i.dget(a, key)
        if value.kind != minString:
          raiseInvalid(err)
        yaml &= "$1: $2\n" % [key.strVal, value.strVal]
      i.push(yaml.strip.newVal)
    except:
      raiseInvalid(err)

  def.symbol("loglevel") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    var str = s.getString
    when defined(mini):
      echo "Log level: ", minilogger.setLogLevel(str)
    else:
      echo "Log level: ", niftylogger.setLogLevel(str)

  def.symbol("loglevel?") do (i: In):
    when defined(mini):
      i.push minilogger.getLogLevel().newVal
    else:
      i.push niftylogger.getLogLevel().newVal

  # Language constructs

  def.symbol("define") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    var isQuot = q1.isQuotation
    q1 = @[q1].newVal
    symbol = sym.getString
    when not defined(mini):
      if not symbol.match USER_SYMBOL_REGEX:
        raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[define] $1 = $2" % [symbol, $q1]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false, quotation: isQuot)
    
  def.symbol("typealias") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let sym = vals[0].getString
    var s = vals[1].getString
    if not i.validType(s):
      raiseInvalid("Invalid type expression: $#" % s)
    let symbol = "typealias:"&sym
    when not defined(mini):
      if not sym.match USER_SYMBOL_REGEX:
        raiseInvalid("Symbol identifier '$1' contains invalid characters." % sym)
    info "[typealias] $1 = $2" % [sym, s]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: s.newVal, sealed: false, quotation: false)
    
  def.symbol("lambda") do (i: In):
    let vals = i.expect("'sym", "quot")
    let sym = vals[0]
    var q1 = vals[1]
    var symbol: string
    symbol = sym.getString
    when not defined(mini):
      if not symbol.match USER_SYMBOL_REGEX:
        raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[lambd] $1 = $2" % [symbol, $q1]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false, quotation: true)
    
  def.symbol("bind") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    var isQuot = q1.isQuotation
    q1 = @[q1].newVal
    symbol = sym.getString
    info "[bind] $1 = $2" % [symbol, $q1]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1, quotation: isQuot))
    if not res:
      raiseUndefined("Attempting to bind undefined symbol: " & symbol)
      
  def.symbol("lambda-bind") do (i: In):
    let vals = i.expect("'sym", "quot")
    let sym = vals[0]
    var q1 = vals[1] 
    var symbol: string
    symbol = sym.getString
    info "[lambda-bind] $1 = $2" % [symbol, $q1]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1, quotation: true))
    if not res:
      raiseUndefined("Attempting to lambda-bind undefined symbol: " & symbol)

  def.symbol("delete-symbol") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    let res = i.scope.delSymbol(sym.getString) 
    if not res:
      raiseUndefined("Attempting to delete undefined symbol: " & sym.getString)
      
  def.symbol("delete-sigil") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0]
    let res = i.scope.delSigil(sym.getString) 
    if not res:
      raiseUndefined("Attempting to delete undefined sigil: " & sym.getString)

  def.symbol("scope") do (i: In):
    var dict = newDict(i.scope.parent)
    dict.objType = "module"
    dict.filename = i.filename
    dict.scope = i.scope
    i.push dict

  def.symbol("parent-scope") do (i: In):
    let vals = i.expect("dict")
    let d = vals[0]
    if d.scope.parent.isNil:
      i.push newNull()
      return
    var dict = newDict(d.scope.parent)
    dict.objType = "module"
    dict.filename = i.filename
    dict.scope = d.scope.parent
    i.push dict

  def.symbol("type") do (i: In):
    let vals = i.expect("a")
    i.push vals[0].typeName.newVal

  def.symbol("symbol-help") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0].getString
    if i.scope.hasSymbol(s):
      let sym = i.scope.getSymbol(s)
      if not sym.doc.isNil and sym.doc.kind == JObject:
        var doc = i.fromJson(sym.doc)
        doc.objType = "help"
        i.push doc
        return
      elif HELP["operators"].hasKey(s):
        var doc = i.fromJson(HELP["operators"][s])
        doc.objType = "help"
        i.push doc
        return
    i.push nil.newVal

  def.symbol("sigil-help") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0].getString
    if i.scope.hasSigil(s):
      let sym = i.scope.getSigil(s)
      if not sym.doc.isNil and sym.doc.kind == JObject:
        var doc = i.fromJson(sym.doc)
        doc.objType = "help"
        i.push doc
        return
      elif HELP["operators"].hasKey(s):
        var doc =i.fromJson(HELP["operators"][s])
        doc.objType = "help"
        i.push doc
        return
    i.push nil.newVal

  def.symbol("help") do (i: In):
    if i.stack.len == 0 or not i.stack[i.stack.len-1].isStringLike:
      warn "Specify a quoted symbol or string to show its help documentation, e.g. 'puts help"
      return
    let s = i.pop.getString
    var found = false
    var foundDoc = false
    let displayDoc = proc (j: JsonNode) =
      echo "=== $# [$#]" % [j["name"].getStr, j["kind"].getStr]
      if j.hasKey("signature"):
        echo j["signature"].getStr
      if j.hasKey("description"):
        let desc = j["description"].getStr
        if desc.len != 0:
          let lines = desc.split("\n")
          echo ""
          for l in lines:
            echo "  " & l
      echo "==="
    if i.scope.hasSymbol(s):
      found = true
      let sym = i.scope.getSymbol(s)
      if not sym.doc.isNil and sym.doc.kind == JObject:
        foundDoc = true
        displayDoc(sym.doc)
      elif HELP["operators"].hasKey(s):
        foundDoc = true
        displayDoc HELP["operators"][s]
    if i.scope.hasSigil(s):
      found = true
      let sym = i.scope.getSigil(s)
      if not sym.doc.isNil and sym.doc.kind == JObject:
        foundDoc = true
        displayDoc(sym.doc)
      elif HELP["sigils"].hasKey(s):
        foundDoc = true
        displayDoc HELP["sigils"][s]
    if not found:
      warn "Undefined symbol or sigil: $#" % s
    elif not foundDoc:
      warn "No documentation found for symbol or sigil: $#" % s

  def.symbol("import") do (i: In):
    var vals = i.expect("'sym")
    let rawName = vals[0]
    var name: string
    name = rawName.getString
    var op = i.scope.getSymbol(name)
    i.apply(op)
    vals = i.expect("dict:module")
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
    let vals = i.expect("str")
    let s = vals[0]
    i.eval s.strVal
    
  def.symbol("quit") do (i: In):
    i.push 0.newVal
    i.pushSym "exit"

  def.symbol("parse") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    i.push i.parse s.strVal

  def.symbol("source") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    let str = s.getString
    let sym = i.scope.getSymbol(str)
    if sym.kind == minValOp:
      i.push sym.val
    else:
      raiseInvalid("No source available for native symbol '$1'." % str)

  def.symbol("invoke") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0].getString
    let parts = s.split("/")
    if parts.len < 2:
      raiseInvalid("Dictionary identifier not specified")
    i.pushSym parts[0]
    for p in 0..parts.len-2:
      let vals = i.expect("dict")
      let mdl = vals[0]
      let symId = parts[p+1] 
      let origScope = i.scope
      i.scope = mdl.scope
      i.scope.parent = origScope
      let sym = i.scope.getSymbol(symId)
      i.apply(sym)
      i.scope = origScope

  def.symbol("raise") do (i: In):
    let vals = i.expect("dict")
    let err = vals[0]
    if err.dhas("error".newVal) and err.dhas("message".newVal):
      raiseRuntime("($1) $2" % [i.dget(err, "error".newVal).getString, i.dget(err, "message").getString], err)
    else:
      raiseInvalid("Invalid error dictionary")

  def.symbol("format-error") do (i: In):
    let vals = i.expect("dict:error")
    let err = vals[0]
    if err.dhas("error".newVal) and err.dhas("message".newVal):
      var msg: string
      var list = newSeq[MinValue]()
      list.add i.dget(err, "message")
      if err.dhas("symbol"):
        list.add i.dget(err, "symbol")
      if err.dhas("filename"):
        list.add i.dget(err, "filename")
      if err.dhas("line"):
        list.add i.dget(err, "line")
      if err.dhas("column"):
        list.add i.dget(err, "column")
      if list.len <= 3:
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
      i.push e.data
      i.dequote(catch)
    except:
      if not hasCatch:
        return
      let e = getCurrentException()
      var res = newDict(i.scope)
      var err = $e.name
      let col = err.find(":")
      if col >= 0:
        err = err[0..col-1]
      res.objType = "error"
      i.dset(res, "error", err.newVal)
      i.dset(res, "message", e.msg.newVal)
      if i.currSym.getString != "": # TODO investigate when this happens
        i.dset(res, "symbol", i.currSym)
        i.dset(res, "filename", i.currSym.filename.newVal)
      i.dset(res, "line", i.currSym.line.newVal)
      i.dset(res, "column", i.currSym.column.newVal)
      i.push res
      i.dequote(catch)
    finally:
      if hasFinally:
        i.dequote(final)

  def.symbol("quote") do (i: In):
    let vals = i.expect("a")
    let a = vals[0]
    i.push @[a].newVal
  
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
    i.dequote(b)
    var check = i.pop
    while check.boolVal == true:
      i.dequote(d)
      i.dequote(b)
      check = i.pop

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
    i.push pkgVersion.newVal

  def.symbol("seal-symbol") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0].getString
    var s = i.scope.getSymbol(sym) 
    s.sealed = true
    i.scope.setSymbol(sym, s, true)
    
  def.symbol("seal-sigil") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0].getString
    var s = i.scope.getSigil(sym) 
    s.sealed = true
    i.scope.setSigil(sym, s, true)

  def.symbol("unseal-symbol") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0].getString
    var s = i.scope.getSymbol(sym) 
    s.sealed = false
    i.scope.setSymbol(sym, s, true)
  
  def.symbol("unseal-sigil") do (i: In):
    let vals = i.expect("'sym")
    let sym = vals[0].getString
    var s = i.scope.getSigil(sym) 
    when not defined(mini):
      if not sym.match USER_SYMBOL_REGEX:
        # Prevent accidentally unsealing system sigils
        # Not that they can redefined, but still
        raiseInvalid("Attempting to unseal system sigil: " & sym)
    s.sealed = false
    i.scope.setSigil(sym, s, true)

  def.symbol("args") do (i: In):
    var args = newSeq[MinValue](0)
    for kind, key, val in getopt():
      case kind:
        of cmdArgument:
          args.add key.newVal
        else:
          discard
    i.push args.newVal

  def.symbol("opts") do (i: In):
    var opts = newDict(i.scope) 
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
  
  def.symbol("expect") do (i: In):
    var q: MinValue
    i.reqQuotationOfSymbols q
    i.push(i.expect(q.qVal.mapIt(it.getString())).reversed.newVal)
    
  def.symbol("infix-dequote") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    proc infix(i: In, q: MinValue): MinValue =
      var ops = newSeq[MinValue](0)
      var res = newSeq[MinValue](0).newVal
      for x in q.qVal:
        if x.isSymbol:
          ops.add x
        else:
          if x.isQuotation:
            res.qVal.add i.infix(x)
          else:
            res.qVal.add x
          if ops.len > 0:
            res.qVal.add ops.pop
            i.dequote(res)
            res = newSeq[MinValue](0).newVal
      return i.pop
    i.push i.infix(q)
    
  def.symbol("prefix-dequote") do (i: In):
    let vals = i.expect("quot")
    var q = vals[0]
    q.qVal.reverse
    i.dequote(q)

  def.symbol("compiled?") do (i: In):
    i.push MINCOMPILED.newVal

  def.symbol("line-info") do (i: In):
    var d = newDict(i.scope)
    i.dset(d, "filename", i.currSym.filename.newVal)
    i.dset(d, "line", i.currSym.line.newVal)
    i.dset(d, "column", i.currSym.column.newVal)
    i.push d

  # Converters

  def.symbol("string") do (i: In):
    let s = i.pop
    i.push(($$s).newVal)

  def.symbol("boolean") do (i: In):
    let v = i.pop
    let strcheck = (v.isString and (v.getString == "false" or v.getString == ""))
    let intcheck = v.isInt and v.intVal == 0
    let floatcheck = v.isFloat and v.floatVal == 0
    let boolcheck = v.isBool and v.boolVal == false
    let quotcheck = v.isQuotation and v.qVal.len == 0
    if v.isNull or strcheck or intcheck or floatcheck or boolcheck or quotcheck:
      i.push false.newVal
    else:
      i.push true.newVal

  def.symbol("integer") do (i: In):
    let s = i.pop
    if s.isString:
      i.push s.getString.parseInt.newVal
    elif s.isNull:
      i.push 0.int.newVal
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
    elif s.isNull:
      i.push 0.int.newVal
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
    when defined(mini):
      i.push "$ ".newVal
    else:
      i.eval(""""[$1]\n$$ " (.) => %""")

  def.symbol("quotesym") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    i.push(@[i.newSym(s.strVal)].newVal)

  # Sigils

  def.sigil("'") do (i: In):
    i.pushSym("quotesym")

  def.sigil(":") do (i: In):
    i.pushSym("define")

  def.sigil("?") do (i: In):
    i.pushSym("help")

  def.sigil("@") do (i: In):
    i.pushSym("bind")

  def.sigil("*") do (i: In):
    i.pushSym("invoke")

  def.sigil(">") do (i: In):
    i.pushSym("save-symbol")

  def.sigil("<") do (i: In):
    i.pushSym("load-symbol")

  def.sigil("^") do (i: In):
    i.pushSym("lambda")
    
  def.sigil("~") do (i: In):
    i.pushSym("lambda-bind")

  # Shorthand symbol aliases

  def.symbol("=-=") do (i: In):
    i.pushSym("expect-empty-stack")

  def.symbol(":") do (i: In):
    i.pushSym("define")
  
  def.symbol("?") do (i: In):
    i.pushSym("help")

  def.symbol("@") do (i: In):
    i.pushSym("bind")
    
  def.symbol("^") do (i: In):
    i.pushSym("lambda")
    
  def.symbol("~") do (i: In):
    i.pushSym("lambda-bind")

  def.symbol("'") do (i: In):
    i.pushSym("quotesym")

  def.symbol("->") do (i: In):
    i.pushSym("dequote")
    
  def.symbol("::") do (i: In):
    i.pushSym("operator")
    
  def.symbol("=>") do (i: In):
    i.pushSym("apply")
    
  def.symbol("==>") do (i: In):
    discard # used within operator defs
    
  def.symbol("return") do (i: In):
    discard # used within operator defs
    
  def.symbol(">>") do (i: In):
    i.pushSym("prefix-dequote")
    
  def.symbol("><") do (i: In):
    i.pushSym("infix-dequote")

  def.finalize("ROOT")
