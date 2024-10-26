import
  std/[critbits,
  strutils,
  json,
  parseopt,
  algorithm,
  math,
  streams,
  random,
  bitops,
  macros,
  tables,
  sequtils,
  sets,
  uri,
  nre,
  os,
  logging]
import
  minline
import
  ../core/baseutils,
  ../core/niftylogger,
  ../core/env,
  ../core/meta,
  ../core/parser,
  ../core/value,
  ../core/interpreter,
  ../core/utils

proc floatCompare(n1, n2: MinValue): bool =
  let
    a: float = if n1.kind != minFloat: n1.intVal.float else: n1.floatVal
    b: float = if n2.kind != minFloat: n2.intVal.float else: n2.floatVal
  if a.classify == fcNan and b.classify == fcNan:
    return true
  else:
    const
      FLOAT_MIN_NORMAL = 2e-1022
      FLOAT_MAX_VALUE = (2-2e-52)*2e1023
      epsilon = 0.00001
    let
      absA = abs(a)
      absB = abs(b)
      diff = abs(a - b)
    if a == b:
      return true
    elif a == 0 or b == 0 or diff < FLOAT_MIN_NORMAL:
      return diff < (epsilon * FLOAT_MIN_NORMAL)
    else:
      return diff / min((absA + absB), FLOAT_MAX_VALUE) < epsilon

proc processTokenValue(v: string, t: MinTokenKind): string =
  case t:
    of tkEof:
      return ""
    of tkString:
      return v.escapeJson
    of tkLineComment:
      return ";$#" % [v]
    of tkLineDocComment:
      return ";;$#" % [v]
    of tkBlockDocComment:
      return "#||$#||#" % [v]
    of tkBlockComment:
      return "#|$#|#" % [v]
    of tkCommand:
      return "[$#]" % [v]
    else:
      return v

proc global_module*(i: In) =
  let def = i.scope

  const HELPFILE = "../../help.json".slurp
  let HELP = HELPFILE.parseJson

  def.symbol("from-json") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    i.push i.fromJson(s.getString.parseJson)

  def.symbol("to-json") do (i: In):
    let vals = i.expect "a"
    let q = vals[0]
    i.push(($((i%q).pretty)).newVal)

  # Save/load symbols

  def.symbol("save-symbol") do (i: In):
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
    i.scope.symbols[sym] = MinOperator(kind: minValOp, val: val,
        quotation: true)

  def.symbol("saved-symbols") do (i: In):
    var q = newSeq[MinValue](0)
    let json = MINSYMBOLS.readFile.parseJson
    for k, v in json.pairs:
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
    var m = s.getString
    if not file.endsWith(".min"):
      file = file & ".min"
    info("[require] File: ", file)
    let lookup = proc (filename: string): string =
      # First check in current folder
      result = simplifyPath(filename, file)
      if result.fileExists:
        return
      # then check for a mmm...
      let localDir = result.parentDir
      # ...locally...
      let localModuleDir = localDir/"mmm"/m
      if localModuleDir.dirExists:
        let versions = localModuleDir.walkDir.toSeq.filterIt(it.kind == pcDir or
            it.kind == pcLinkToDir)
        if versions.len > 0:
          let localModuleVersion = versions[0].path
          result = localModuleVersion/"index.min"
          if result.fileExists:
            return
      # ...and then globally.
      let globalModuleDir = HOME/"mmm"/m
      if globalModuleDir.dirExists:
        let versions = globalModuleDir.walkDir.toSeq.filterIt(it.kind ==
            pcDir or it.kind == pcLinkToDir)
        if versions.len > 0:
          let globalModuleVersion = versions[0].path
          result = globalModuleVersion/"index.min"
          if result.fileExists:
            return
    let f = lookup(i.filename)
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
          # We need to set the mdl field of minOperators
          # In case of modules, or internal calls will not work
          var v = value
          v.mdl = mdl
          mdl.scope.symbols[key] = v
        i.push(mdl)
    else:
      if not f.fileExists:
        raiseInvalid("Unable to resolve module '$1'." % m)
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

  def.symbol("operator") do (i: In):
    let vals = i.expect("quot");
    let q = vals[0]
    if q.qVal.len != 4:
      raiseInvalid("Invalid operator definition")
    let tv = q.qVal[0]
    let t = tv.symVal
    let nv = q.qVal[1]
    if not tv.isSymbol or (not ["symbol", "sigil", "typeclass",
        "constructor"].contains(t)):
      raiseInvalid("Incorrect operator type specified (it must be 'symbol', 'sigil', 'constructor', or 'typeclass' - found '$#')" % tv.symVal)
    if not nv.isSymbol:
      raiseInvalid("Operator name must be a symbol")
    var n = nv.symVal
    if not n.contains(re(USER_SYMBOL_REGEX)):
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
    var inExpects = newSeq[string](0)
    var inVars = newSeq[string](0)
    var outExpects = newSeq[string](0)
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
          raiseInvalid("Invalid type '$#' in generic in signature at position $#" %
              [$t, $(c+1)])
        if g[0] != ':' and g[0] != '^':
          raiseInvalid("No mapping symbol specified in generic in signature at position $#" %
              $(c+1))
        v = g[1..g.len-1]
        generics[v] = t
      else:
        v = vv.symVal
      if check:
        if v == "==>":
          o = true
        elif not i.validType(v) and not generics.hasKey(v):
          raiseInvalid("Invalid type '$#' specified in signature at position $#" %
              [v, $(c+1)])
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
          raiseInvalid("No capturing symbol specified in signature at position $#" %
              $(c+1))
        else:
          if o:
            if v[0] == '^' and outExpects[outExpects.len-1] != "quot":
              raiseInvalid("Only quotations can be captured to a lambda, found $# instead at position $#" %
                  [outExpects[outExpects.len-1], $(c+1)])
            rawOutVars.add v
            outVars.add v[1..v.len-1]
          else:
            if v[0] == '^':
              raiseInvalid("A lambda capturing symbol was specified in signature at position $#. Lambda capturing symbols are only allowed for output values" %
                  $(c+1))
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
      except CatchableError:
        generics = origGenerics
        raise
      i.withScope():
        # Inject variables for mapped inputs
        for k in 0..inVars.len-1:
          var iv = inVals[k]
          if iv.isQuotation:
            iv = @[iv].newVal
          i.scope.symbols[inVars[k]] = MinOperator(kind: minValOp,
              sealed: false, val: iv, quotation: inVals[k].isQuotation)
        # Inject variables for mapped outputs
        for k in 0..outVars.len-1:
          i.scope.symbols[outVars[k]] = MinOperator(kind: minValOp,
              sealed: false, val: @[newNull()].newVal, quotation: true)
        # Actually execute the body of the operator
        if DEV:
          var endSnapshot: seq[MinValue]
          var snapShot: seq[MinValue]
          try:
            snapshot = deepCopy(i.stack)
            i.dequote bv
            endSnapshot = i.stack
            let d = snapshot.diff(endSnapshot)
            if d.len > 0:
              raiseInvalid("Operator '$#' is polluting the stack -- $#" % [n, $d.newVal])
          except MinReturnException:
            discard
        else:
          try:
            i.dequote bv
          except MinReturnException:
            discard
        # Validate output
        for k in 0..outVars.len-1:
          var x = i.scope.symbols[outVars[k]].val
          if rawOutVars[k][0] == ':':
            x = x.qVal[0]
          if t == "constructor":
            x.objType = n
          if DEV:
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
              raiseInvalid("Invalid value for output symbol '$#'. Expected $#, found $#" %
                  [outVars[k], tp, $x])
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

  def.symbol("print") do (i: In):
    let a = i.peek
    a.print

  def.symbol("puts") do (i: In):
    let a = i.peek
    echo $$a

  def.symbol("gets") do (i: In):
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
    i.push((not i.scope.getSymbol(vals[0].getString).isNull).newVal)

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
    except CatchableError:
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
    except CatchableError:
      raiseInvalid(err)

  def.symbol("loglevel") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    var str = s.getString
    echo "Log level: ", niftylogger.setLogLevel(str)

  def.symbol("loglevel?") do (i: In):
    i.push niftylogger.getLogLevel().newVal

  # Language constructs

  def.symbol("define") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    q1 = @[q1].newVal
    symbol = sym.getString
    if not symbol.contains re(USER_PATH_SYMBOL_REGEX):
      raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[define] $1 = $2" % [symbol, $q1]
    i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1,
        sealed: false, quotation: q1.isQuotation), false, true)

  def.symbol("typealias") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let sym = vals[0].getString
    var s = vals[1].getString
    if not i.validType(s):
      raiseInvalid("Invalid type expression: $#" % s)
    let symbol = "typealias:"&sym
    if not sym.contains re(USER_SYMBOL_REGEX):
      raiseInvalid("Symbol identifier '$1' contains invalid characters." % sym)
    info "[typealias] $1 = $2" % [sym, s]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: s.newVal,
        sealed: false, quotation: false)

  def.symbol("lambda") do (i: In):
    let vals = i.expect("'sym", "quot")
    let sym = vals[0]
    var q1 = vals[1]
    var symbol: string
    symbol = sym.getString
    if not symbol.contains re(USER_SYMBOL_REGEX):
      raiseInvalid("Symbol identifier '$1' contains invalid characters." % symbol)
    info "[lambda] $1 = $2" % [symbol, $q1]
    if i.scope.symbols.hasKey(symbol) and i.scope.symbols[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed symbol '$1'" % [symbol])
    i.scope.symbols[symbol] = MinOperator(kind: minValOp, val: q1,
        sealed: false, quotation: true)

  def.symbol("define-sigil") do (i: In):
    let vals = i.expect("'sym", "quot")
    let sym = vals[0]
    var q1 = vals[1]
    var symbol: string
    symbol = sym.getString
    if not symbol.contains re(USER_SYMBOL_REGEX):
      raiseInvalid("Sigil identifier '$1' contains invalid characters." % symbol)
    info "[define-sigil] $1 = $2" % [symbol, $q1]
    if i.scope.sigils.hasKey(symbol) and i.scope.sigils[symbol].sealed:
      raiseUndefined("Attempting to redefine sealed sigil '$1'" % [symbol])
    i.scope.sigils[symbol] = MinOperator(kind: minValOp, val: q1, sealed: false,
        quotation: true)

  def.symbol("bind") do (i: In):
    let vals = i.expect("'sym", "a")
    let sym = vals[0]
    var q1 = vals[1] # existing (auto-quoted)
    var symbol: string
    var isQuot = q1.isQuotation
    q1 = @[q1].newVal
    symbol = sym.getString
    info "[bind] $1 = $2" % [symbol, $q1]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1,
        quotation: isQuot))
    if not res:
      raiseUndefined("Attempting to bind undefined symbol: " & symbol)

  def.symbol("lambda-bind") do (i: In):
    let vals = i.expect("'sym", "quot")
    let sym = vals[0]
    var q1 = vals[1]
    var symbol: string
    symbol = sym.getString
    info "[lambda-bind] $1 = $2" % [symbol, $q1]
    let res = i.scope.setSymbol(symbol, MinOperator(kind: minValOp, val: q1,
        quotation: true))
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
    let sym = i.scope.getSymbol(s)
    if not sym.isNull:
      if not sym.doc.isNil and sym.doc.kind == JObject:
        var doc = i.fromJson(sym.doc)
        doc.objType = "help"
        i.push doc
        return
      elif HELP["symbols"].hasKey(s):
        var doc = i.fromJson(HELP["symbols"][s])
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
      elif HELP["symbols"].hasKey(s):
        var doc = i.fromJson(HELP["symbols"][s])
        doc.objType = "help"
        i.push doc
        return
    i.push nil.newVal

  def.symbol("help") do (i: In):
    if i.stack.len == 0 or not i.stack[i.stack.len-1].isStringLike:
      warn "Specify a quoted symbol or string to show its help documentation, e.g. 'puts help"
      return
    var s = i.pop.getString
    var found = false
    var foundDoc = false
    let displayDoc = proc (j: JsonNode) =
      if j.hasKey("module"):
        echo "=== $#.$# [$#]" % [j["module"].getStr, j["name"].getStr, j["kind"].getStr]
      else:
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
    let sym = i.scope.getSymbol(s)
    if not sym.isNull:
      found = true
      if not sym.doc.isNil and sym.doc.kind == JObject:
        foundDoc = true
        displayDoc(sym.doc)
        return
      var mdl = ""
      if s.contains('.'):
        let parts = s.split(".")
        mdl = parts[0]
        s = parts[1]
      if HELP["symbols"].hasKey(s) and (mdl == "" or mdl == HELP["symbols"][
          s]["module"].getStr):
        foundDoc = true
        displayDoc HELP["symbols"][s]
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
    info("[import] Importing: $1 ($2 symbols, $3 sigils)" % [name,
        $mdl.scope.symbols.len, $mdl.scope.sigils.len])
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
      raiseInvalid("Unable to display source: '$1' is an operator." % str)

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
      if not i.scope.parent.isNil:
        i.scope.parent = origScope
      let sym = i.scope.getSymbol(symId)
      i.apply(sym)
      i.scope = origScope

  def.symbol("raise") do (i: In):
    let vals = i.expect("dict")
    let err = vals[0]
    if err.dhas("error".newVal) and err.dhas("message".newVal):
      raiseRuntime("($1) $2" % [i.dget(err, "error".newVal).getString, i.dget(
          err, "message").getString], err)
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
        msg = "$3($4,$5) `$2`: $1" % [$$list[0], $$list[1], $$list[2], $$list[
            3], $$list[4]]
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
    if (not code.isQuotation) or (hasCatch and not catch.isQuotation) or (
        hasFinally and not final.isQuotation):
      raiseInvalid("Quotation must contain at least one quotation")
    try:
      i.dequote(code)
    except MinRuntimeError:
      if not hasCatch:
        return
      let e = (MinRuntimeError)getCurrentException()
      i.push e.data
      i.dequote(catch)
    except CatchableError:
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
    var t = vals[0].intVal
    var prog = vals[1]
    if t > 0:
      for c in 1..t:
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
    if not sym.contains re(USER_SYMBOL_REGEX):
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

  def.symbol("dev") do (i: In):
    DEV = not DEV
    notice "Development Mode: ", DEV

  def.symbol("dev?") do (i: In):
    i.push DEV.newVal

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
    i.eval(""""[$1]\n$$ " (sys.pwd) => %""")

  def.symbol("quotesym") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    i.push(@[i.newSym(s.strVal)].newVal)

  def.symbol("quotecmd") do (i: In):
    let vals = i.expect("str")
    let s = vals[0]
    i.push(@[newCmd(s.strVal)].newVal)

  def.symbol("tokenize") do (i: In):
    let vals = i.expect("str")
    let s = vals[0].getString
    var i2 = i.copy("string")
    i2.open(newStringStream(s), "string")
    var p = i2.parser
    var t = p.getToken()
    var q = newSeq[MinValue](0)
    var dict = newDict(i.scope)
    i.dset(dict, "type", newVal($t))
    i.dset(dict, "value", p.a.processTokenValue(t).newVal)
    q.add dict
    while t != tkEof:
      t = p.getToken()
      var dict = newDict(i.scope)
      i.dset(dict, "type", newVal($t))
      i.dset(dict, "value", p.a.processTokenValue(t).newVal)
      q.add dict
    i.push q.newVal

  def.symbol("get-env") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0]
    i.push a.getString.getEnv.newVal

  def.symbol("put-env") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let key = vals[0]
    let value = vals[1]
    key.getString.putEnv value.getString

  # Numeric operations

  def.symbol("nan") do (i: In):
    i.push newVal(NaN)

  def.symbol("inf") do (i: In):
    i.push newVal(Inf)

  def.symbol("-inf") do (i: In):
    i.push newVal(NegInf)

  def.symbol("+") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal + b.intVal)
      else:
        i.push newVal(a.intVal.float + b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal + b.floatVal)
      else:
        i.push newVal(a.floatVal + b.intVal.float)

  def.symbol("-") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(b.intVal - a.intVal)
      else:
        i.push newVal(b.floatVal - a.intVal.float)
    else:
      if b.isFloat:
        i.push newVal(b.floatVal - a.floatVal)
      else:
        i.push newVal(b.intVal.float - a.floatVal)

  def.symbol("*") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal * b.intVal)
      else:
        i.push newVal(a.intVal.float * b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal * b.floatVal)
      else:
        i.push newVal(a.floatVal * b.intVal.float)

  def.symbol("/") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(b.intVal.int / a.intVal.int)
      else:
        i.push newVal(b.floatVal / a.intVal.float)
    else:
      if b.isFloat:
        i.push newVal(b.floatVal / a.floatVal)
      else:
        i.push newVal(b.intVal.float / a.floatVal)

  def.symbol("randomize") do (i: In):
    randomize()

  def.symbol("random") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push n.intVal.int.rand.newVal

  def.symbol("div") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push(newVal(a.intVal div b.intVal))

  def.symbol("mod") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push(newVal(a.intVal mod b.intVal))

  def.symbol("succ") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal + 1)

  def.symbol("pred") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal - 1)

  def.symbol("even?") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal mod 2 == 0)

  def.symbol("odd?") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    i.push newVal(n.intVal mod 2 != 0)

  def.symbol("bitnot") do (i: In):
    let vals = i.expect("int")
    let a = vals[0]
    i.push newVal(not a.intVal)

  def.symbol("shl") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push newVal(a.intVal shl b.intVal)

  def.symbol("shr") do (i: In):
    let vals = i.expect("int", "int")
    let b = vals[0]
    let a = vals[1]
    i.push newVal(a.intVal shr b.intVal)

  def.symbol("sum") do (i: In):
    var s: MinValue
    i.reqQuotationOfNumbers s
    var c = 0.float
    var isInt = true
    for n in s.qVal:
      if n.isFloat:
        isInt = false
        c = + n.floatVal
      else:
        c = c + n.intVal.float
    if isInt:
      i.push c.int.newVal
    else:
      i.push c.newVal

  def.symbol("product") do (i: In):
    var s: MinValue
    i.reqQuotationOfNumbers s
    var c = 1.float
    var isInt = true
    for n in s.qVal:
      if n.isFloat:
        isInt = false
        c = c * n.floatVal
      else:
        c = c * n.intVal.float
    if isInt:
      i.push c.int.newVal
    else:
      i.push c.newVal

  def.symbol("avg") do (i: In):
    var s: MinValue
    i.reqQuotationOfNumbers s
    var c = 0.float
    for n in s.qVal:
      if n.isFloat:
        c = + n.floatVal
      else:
        c = c + n.intVal.float
    c = c / len(s.qVal).float
    i.push c.newVal

  def.symbol("med") do (i: In):
    var s: MinValue
    i.reqQuotationOfNumbers s
    let first = s.qVal[(s.qVal.len-1) div 2]
    let second = s.qVal[((s.qVal.len-1) div 2)+1]
    if s.qVal.len mod 2 == 1:
      i.push first
    else:
      if first.isFloat:
        if second.isFloat:
          i.push ((first.floatVal+second.floatVal)/2).newVal
        else:
          i.push ((first.floatVal+second.intVal.float)/2).newVal
      else:
        if second.isFloat:
          i.push ((first.intVal.float+second.floatVal)/2).newVal
        else:
          i.push ((first.intVal+second.intVal).float/2).newVal

  def.symbol("range") do (i: In):
    var s: MinValue
    i.reqQuotationOfIntegers s
    var a = s.qVal[0]
    var b = s.qVal[1]
    var step = 1.newVal
    var res = newSeq[MinValue](0)
    if len(s.qVal) == 3:
      a = s.qVal[0]
      b = s.qVal[1]
      step = s.qVal[2]
    var j = a
    if a.intVal < b.intVal:
      while j.intVal <= b.intVal:
        res.add j
        j = (j.intVal + step.intVal).newVal
    else:
      while j.intVal >= b.intVal:
        res.add j
        j = (j.intVal - step.intVal).newVal
    i.push res.newVal

  def.symbol("base") do (i: In):
    let vals = i.expect("'sym")
    let base = vals[0].getString
    if not ["dec", "hex", "oct", "bin"].contains(base):
      raiseInvalid("[base] Invalid base '$#'. Expected one of: 'dec', 'oct', 'hex', 'bin'" %
          [base])
    case base:
    of "dec":
      NUMBASE = baseDec
    of "oct":
      NUMBASE = baseOct
    of "hex":
      NUMBASE = baseHex
    of "bin":
      NUMBASE = baseBin

  def.symbol("base?") do (i: In):
    case NUMBASE:
    of baseDec:
      i.push "dec".newVal
    of baseOct:
      i.push "oct".newVal
    of baseHex:
      i.push "hex".newVal
    of baseBin:
      i.push "bin".newVal

  def.symbol("bitand") do (i: In):
    let args = i.expect("int", "int")
    i.push (bitand(args[0].intVal, args[1].intVal)).newVal

  def.symbol("bitor") do (i: In):
    let args = i.expect("int", "int")
    i.push (bitor(args[0].intVal, args[1].intVal)).newVal

  def.symbol("bitxor") do (i: In):
    let args = i.expect("int", "int")
    i.push (bitxor(args[1].intVal, args[0].intVal)).newVal

  def.symbol("bitclear") do (i: In):
    var q: MinValue
    i.reqQuotationOfIntegers(q)
    var vals = i.expect("int")
    var val = vals[0].intVal
    for n in q.qVal:
      val.clearBits(n.intVal)
    i.push val.newVal

  def.symbol("bitset") do (i: In):
    var q: MinValue
    i.reqQuotationOfIntegers(q)
    var vals = i.expect("int")
    var val = vals[0].intVal
    for n in q.qVal:
      val.setBits(n.intVal)
    i.push val.newVal

  def.symbol("bitflip") do (i: In):
    var q: MinValue
    i.reqQuotationOfIntegers(q)
    var vals = i.expect("int")
    var val = vals[0].intVal
    for n in q.qVal:
      val.flipBits(n.intVal)
    i.push val.newVal

  def.symbol("bitparity") do (i: In):
    let args = i.expect("int")
    i.push (args[0].intVal.parityBits).newVal

  # Logic Operations

  def.symbol(">") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
      i.push newVal(n1.strVal > n2.strVal)

  def.symbol(">=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float or floatCompare(n1, n2))
    else:
      i.push newVal(n1.strVal >= n2.strVal)

  def.symbol("<") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
      i.push newVal(n1.strVal > n2.strVal)

  def.symbol("<=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float or floatCompare(n1, n2))
    else:
      i.push newVal(n1.strVal >= n2.strVal)

  def.symbol("==") do (i: In):
    var n1, n2: MinValue
    let vals = i.expect("a", "a")
    n1 = vals[0]
    n2 = vals[1]
    if (n1.kind == minFloat or n2.kind == minFloat) and n1.isNumber and n2.isNumber:
      i.push newVal(floatCompare(n1, n2))
    else:
      i.push newVal(n1 == n2)

  def.symbol("!=") do (i: In):
    var n1, n2: MinValue
    let vals = i.expect("a", "a")
    n1 = vals[0]
    n2 = vals[1]
    if (n1.kind == minFloat or n2.kind == minFloat) and n1.isNumber and n2.isNumber:
      i.push newVal(not floatCompare(n1, n2))
    i.push newVal(not (n1 == n2))

  def.symbol("not") do (i: In):
    let vals = i.expect("bool")
    let b = vals[0]
    i.push newVal(not b.boolVal)

  def.symbol("and") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal and b.boolVal)

  def.symbol("expect-all") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    var c = 0
    for v in q.qVal:
      if not v.isQuotation:
        raiseInvalid("A quotation of quotations is expected")
      var vv = v
      i.dequote vv
      let r = i.pop
      c.inc()
      if not r.isBool:
        raiseInvalid("Quotation #$# does not evaluate to a boolean value" % [$c])
      if not r.boolVal:
        i.push r
        return
    i.push true.newVal

  def.symbol("or") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal or b.boolVal)

  def.symbol("expect-any") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    var c = 0
    for v in q.qVal:
      if not v.isQuotation:
        raiseInvalid("A quotation of quotations is expected")
      var vv = v
      i.dequote vv
      let r = i.pop
      c.inc()
      if not r.isBool:
        raiseInvalid("Quotation #$# does not evaluate to a boolean value" % [$c])
      if r.boolVal:
        i.push r
        return
    i.push false.newVal

  def.symbol("xor") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal xor b.boolVal)

  def.symbol("string?") do (i: In):
    if i.pop.kind == minString:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("integer?") do (i: In):
    if i.pop.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("float?") do (i: In):
    if i.pop.kind == minFloat:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("null?") do (i: In):
    if i.pop.kind == minNull:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("number?") do (i: In):
    let a = i.pop
    if a.kind == minFloat or a.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("boolean?") do (i: In):
    if i.pop.kind == minBool:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("quotation?") do (i: In):
    if i.pop.kind == minQuotation:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("quoted-symbol?") do (i: In):
    let item = i.pop
    if item.kind == minQuotation and item.qVal.len == 1 and item.qVal[0].kind == minSymbol:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("stringlike?") do (i: In):
    if i.pop.isStringLike:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("dictionary?") do (i: In):
    if i.pop.isDictionary:
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("type?") do (i: In):
    let vals = i.expect("'sym", "a")
    let t = vals[0].getString
    let v = vals[1]
    let res = i.validateValueType(t, v)
    i.push res.newVal

  def.symbol("&&") do (i: In):
    i.pushSym("expect-all")

  def.symbol("||") do (i: In):
    i.pushSym("expect-any")

  # String operations

  when not defined(nopcre):

    when defined(windows) and defined(amd64):
      {.passL: "-static -L"&getProjectPath()&"/minpkg/vendor/pcre/windows -lpcre".}
    elif defined(linux) and defined(amd64):
      {.passL: "-static -L"&getProjectPath()&"/minpkg/vendor/pcre/linux -lpcre".}
    elif defined(macosx) and defined(amd64):
      {.passL: "-Bstatic -L"&getProjectPath()&"/minpkg/vendor/pcre/macosx -lpcre -Bdynamic".}

    def.symbol("search") do (i: In):
      let vals = i.expect("str", "str")
      let reg = re(vals[0].strVal)
      let str = vals[1]
      let m = str.strVal.find(reg)
      var res = newSeq[MinValue](0)
      if m.isNone:
        res.add "".newVal
        for i in 0..reg.captureCount-1:
          res.add "".newVal
        i.push res.newVal
        return
      let matches = m.get.captures
      res.add m.get.match.newVal
      for i in 0..reg.captureCount-1:
        res.add matches[i].newVal
      i.push res.newVal

    def.symbol("match?") do (i: In):
      let vals = i.expect("str", "str")
      let reg = re(vals[0].strVal)
      let str = vals[1].strVal
      i.push str.find(reg).isSome.newVal

    def.symbol("search-all") do (i: In):
      let vals = i.expect("str", "str")
      var res = newSeq[MinValue](0)
      let reg = re(vals[0].strVal)
      let str = vals[1].strVal
      for m in str.findIter(reg):
        let matches = m.captures
        var mres = newSeq[MinValue](0)
        mres.add m.match.newVal
        for i in 0..reg.captureCount-1:
          mres.add matches[i].newVal
        res.add mres.newval
      i.push res.newVal

    def.symbol("replace-apply") do (i: In):
      let vals = i.expect("quot", "str", "str")
      let q = vals[0]
      let reg = re(vals[1].strVal)
      let s_find = vals[2].strVal
      var i2 = i.copy(i.filename)
      let repFn = proc(match: RegexMatch): string {.closure.} =
        var ss = newSeq[MinValue](0)
        ss.add match.match.newVal
        for s in match.captures:
          if s.isNone:
            ss.add "".newVal
          else:
            ss.add s.get.newVal
        i2.push ss.newVal
        i2.push q
        i2.pushSym "dequote"
        return i2.pop.getString
      i.push s_find.replace(reg, repFn).newVal

    def.symbol("replace") do (i: In):
      let vals = i.expect("str", "str", "str")
      let s_replace = vals[0].strVal
      let reg = re(vals[1].strVal)
      let s_find = vals[2].strVal
      i.push s_find.replace(reg, s_replace).newVal

  def.symbol("interpolate") do (i: In):
    let vals = i.expect("quot", "str")
    var q = vals[0]
    let s = vals[1]
    var strings = newSeq[string](0)
    for el in q.qVal:
      strings.add $$el
    let res = s.strVal % strings
    i.push res.newVal

  def.symbol("apply-interpolate") do (i: In):
    i.pushSym "apply"
    i.pushSym "interpolate"

  def.symbol("strip") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.strip.newVal

  def.symbol("substr") do (i: In):
    let vals = i.expect("int", "int", "'sym")
    let length = vals[0].intVal
    let start = vals[1].intVal
    let s = vals[2].getString
    let index = min(start+length-1, s.len-1)
    i.push s[start..index].newVal

  def.symbol("split") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let sep = re(vals[0].getString)
    let s = vals[1].getString
    var q = newSeq[MinValue](0)
    for e in s.split(sep):
      q.add e.newVal
    i.push q.newVal

  def.symbol("join") do (i: In):
    let vals = i.expect("'sym", "quot")
    let s = vals[0]
    let q = vals[1]
    i.push q.qVal.mapIt($$it).join(s.getString).newVal

  def.symbol("length") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.len.newVal

  def.symbol("lowercase") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.toLowerAscii.newVal

  def.symbol("uppercase") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.toUpperAscii.newVal

  def.symbol("capitalize") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.capitalizeAscii.newVal

  def.symbol("ord") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    if s.getString.len != 1:
      raiseInvalid("Symbol ord requires a string containing a single character.")
    i.push s.getString[0].ord.newVal

  def.symbol("chr") do (i: In):
    let vals = i.expect("int")
    let n = vals[0]
    let c = n.intVal.chr
    i.push ($c).newVal

  def.symbol("titleize") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.split(" ").mapIt(it.capitalizeAscii).join(" ").newVal

  def.symbol("repeat") do (i: In):
    let vals = i.expect("int", "str")
    let n = vals[0]
    let s = vals[1]
    i.push s.getString.repeat(n.intVal).newVal

  def.symbol("indent") do (i: In):
    let vals = i.expect("int", "str")
    let n = vals[0]
    let s = vals[1]
    i.push s.getString.indent(n.intVal).newVal

  def.symbol("indexof") do (i: In):
    let vals = i.expect("str", "str")
    let reg = vals[0]
    let str = vals[1]
    let index = str.strVal.find(reg.strVal)
    i.push index.newVal

  def.symbol("encode-url") do (i: In):
    let vals = i.expect("str")
    let s = vals[0].strVal
    i.push s.encodeUrl.newVal

  def.symbol("decode-url") do (i: In):
    let vals = i.expect("str")
    let s = vals[0].strVal
    i.push s.decodeUrl.newVal

  def.symbol("parse-url") do (i: In):
    let vals = i.expect("str")
    let s = vals[0].strVal
    let u = s.parseUri
    var d = newDict(i.scope)
    d.objType = "url"
    i.dset(d, "scheme", u.scheme.newVal)
    i.dset(d, "username", u.username.newVal)
    i.dset(d, "password", u.password.newVal)
    i.dset(d, "hostname", u.hostname.newVal)
    i.dset(d, "port", u.port.newVal)
    i.dset(d, "path", u.path.newVal)
    i.dset(d, "query", u.query.newVal)
    i.dset(d, "anchor", u.anchor.newVal)
    i.push d

  def.symbol("semver?") do (i: In):
    let vals = i.expect("str")
    let v = vals[0].strVal
    let m = v.match(re"^\d+\.\d+\.\d+$")
    i.push m.isSome.newVal

  def.symbol("from-semver") do (i: In):
    let vals = i.expect("str")
    let v = vals[0].strVal
    let reg = re"^(\d+)\.(\d+)\.(\d+)$"
    let rawMatch = v.match(reg)
    if rawMatch.isNone:
      raiseInvalid("String '$1' is not a basic semver" % v)
    let parts = rawMatch.get.captures
    var d = newDict(i.scope)
    i.dset(d, "major", parts[0].parseInt.newVal)
    i.dset(d, "minor", parts[1].parseInt.newVal)
    i.dset(d, "patch", parts[2].parseInt.newVal)
    i.push d

  def.symbol("to-semver") do (i: In):
    let vals = i.expect("dict")
    let v = vals[0]
    if not v.dhas("major") or not v.dhas("minor") or not v.dhas("patch"):
      raiseInvalid("Dictionary does not contain major, minor and patch keys")
    let major = i.dget(v, "major")
    let minor = i.dget(v, "minor")
    let patch = i.dget(v, "patch")
    if major.kind != minInt or minor.kind != minInt or patch.kind != minInt:
      raiseInvalid("major, minor, and patch values are not integers")
    i.push(newVal("$#.$#.$#" % [$major, $minor, $patch]))

  def.symbol("semver-inc-major") do (i: In):
    i.pushSym("from-semver")
    var d = i.pop
    let cv = i.dget(d, "major")
    let v = cv.intVal + 1
    i.dset(d, "major", v.newVal)
    i.dset(d, "minor", 0.newVal)
    i.dset(d, "patch", 0.newVal)
    i.push(d)
    i.pushSym("to-semver")

  def.symbol("semver-inc-minor") do (i: In):
    i.pushSym("from-semver")
    var d = i.pop
    let cv = i.dget(d, "minor")
    let v = cv.intVal + 1
    i.dset(d, "minor", v.newVal)
    i.dset(d, "patch", 0.newVal)
    i.push(d)
    i.pushSym("to-semver")

  def.symbol("semver-inc-patch") do (i: In):
    i.pushSym("from-semver")
    var d = i.pop
    let cv = i.dget(d, "patch")
    let v = cv.intVal + 1
    i.dset(d, "patch", v.newVal)
    i.push(d)
    i.pushSym("to-semver")

  def.symbol("escape") do (i: In):
    let vals = i.expect("'sym")
    let a = vals[0].getString
    i.push a.escapeEx(true).newVal

  def.symbol("prefix") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let a = vals[1].getString
    let b = vals[0].getString
    var s = b & a
    i.push s.newVal

  def.symbol("suffix") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let a = vals[1].getString
    let b = vals[0].getString
    var s = a & b
    i.push s.newVal

  def.symbol("to-hex") do (i: In):
    let vals = i.expect("int")
    let v = vals[0].intVal
    i.push (("0x"&v.toHex(sizeof(v))).newVal)

  def.symbol("to-oct") do (i: In):
    let vals = i.expect("int")
    let v = vals[0].intVal
    i.push (("0o"&v.toOct(sizeof(v))).newVal)

  def.symbol("to-dec") do (i: In):
    let vals = i.expect("int")
    let v = vals[0].intVal
    i.push ($v).newVal

  def.symbol("to-bin") do (i: In):
    let vals = i.expect("int")
    let v = vals[0].intVal
    i.push (("0b"&v.toBin(sizeof(v))).newVal)

  def.symbol("from-hex") do (i: In):
    let vals = i.expect("'sym")
    i.push fromHex[BiggestInt](vals[0].getString).newVal

  def.symbol("from-oct") do (i: In):
    let vals = i.expect("'sym")
    i.push fromOct[BiggestInt](vals[0].getString).newVal

  def.symbol("from-bin") do (i: In):
    let vals = i.expect("'sym")
    i.push fromBin[BiggestInt](vals[0].getString).newVal

  def.symbol("from-dec") do (i: In):
    let vals = i.expect("'sym")
    i.push parseInt(vals[0].getString).newVal

  def.symbol("%") do (i: In):
    i.pushSym("interpolate")

  def.symbol("=%") do (i: In):
    i.pushSym("apply-interpolate")

  # Sequence operations

  def.symbol("intersection") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = sets.toHashSet(vals[0].qVal)
    let q2 = sets.toHashSet(vals[1].qVal)
    i.push items(sets.intersection(q2, q1)).toSeq.newVal

  def.symbol("union") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = sets.toHashSet(vals[0].qVal)
    let q2 = sets.toHashSet(vals[1].qVal)
    i.push sets.items(sets.union(q2, q1)).toSeq.newVal

  def.symbol("difference") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = sets.toHashSet(vals[0].qVal)
    let q2 = sets.toHashSet(vals[1].qVal)
    i.push sets.items(sets.difference(q2, q1)).toSeq.newVal

  def.symbol("symmetric-difference") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = sets.toHashSet(vals[0].qVal)
    let q2 = sets.toHashSet(vals[1].qVal)
    i.push sets.items(sets.symmetricDifference(q2, q1)).toSeq.newVal

  def.symbol("concat") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = vals[0]
    let q2 = vals[1]
    let q = q2.qVal & q1.qVal
    i.push q.newVal

  def.symbol("first") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    if q.qVal.len == 0:
      raiseOutOfBounds("Quotation is empty")
    i.push q.qVal[0]

  def.symbol("last") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    if q.qVal.len == 0:
      raiseOutOfBounds("Quotation is empty")
    i.push q.qVal[q.qVal.len - 1]

  def.symbol("rest") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    if q.qVal.len == 0:
      raiseOutOfBounds("Quotation is empty")
    i.push q.qVal[1..q.qVal.len-1].newVal

  def.symbol("append") do (i: In):
    let vals = i.expect("quot", "a")
    let q = vals[0]
    let v = vals[1]
    i.push newVal(q.qVal & v)

  def.symbol("prepend") do (i: In):
    let vals = i.expect("quot", "a")
    let q = vals[0]
    let v = vals[1]
    i.push newVal(v & q.qVal)

  def.symbol("get") do (i: In):
    let vals = i.expect("int", "quot")
    let index = vals[0]
    let q = vals[1]
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    i.push q.qVal[ix.int]

  def.symbol("get-raw") do (i: In):
    let vals = i.expect("int", "quot")
    let index = vals[0]
    let q = vals[1]
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    let v = q.qVal[ix.int]
    var rv = newDict(i.scope)
    rv.objType = "rawval"
    i.dset(rv, "type", v.typeName.newVal)
    i.dset(rv, "val", v)
    i.dset(rv, "str", newVal($v))
    i.push rv

  def.symbol("set") do (i: In):
    let vals = i.expect("int", "a", "quot")
    let index = vals[0]
    let val = vals[1]
    var q = newVal(vals[2].qVal)
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    q.qVal[ix.int] = val
    i.push q

  def.symbol("set-sym") do (i: In):
    let vals = i.expect("int", "'sym", "quot")
    let index = vals[0]
    let val = newSym(vals[1].getString)
    var q = newVal(vals[2].qVal)
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    q.qVal[ix.int] = val
    i.push q

  def.symbol("remove") do (i: In):
    let vals = i.expect("int", "quot")
    let index = vals[0]
    let q = vals[1]
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    var res = newSeq[MinValue](0)
    for x in 0..q.qVal.len-1:
      if x == ix:
        continue
      res.add q.qVal[x]
    i.push res.newVal

  def.symbol("insert") do (i: In):
    let vals = i.expect("int", "a", "quot")
    let index = vals[0]
    let val = vals[1]
    let q = vals[2]
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    var res = newSeq[MinValue](0)
    for x in 0..q.qVal.len-1:
      if x == ix:
        res.add val
      res.add q.qVal[x]
    i.push res.newVal

  def.symbol("size") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    i.push q.qVal.len.newVal

  def.symbol("in?") do (i: In):
    let vals = i.expect("a", "quot")
    let v = vals[0]
    let q = vals[1]
    i.push q.qVal.contains(v).newVal

  def.symbol("map") do (i: In):
    let vals = i.expect("quot", "quot")
    var prog = vals[0]
    let list = vals[1]
    var res = newSeq[MinValue](0)
    for litem in list.qVal:
      i.push litem
      i.dequote(prog)
      res.add i.pop
    i.push res.newVal

  def.symbol("quote-map") do (i: In):
    let vals = i.expect("quot")
    let list = vals[0]
    var res = newSeq[MinValue](0)
    for litem in list.qVal:
      res.add @[litem].newVal
    i.push res.newVal

  def.symbol("reverse") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    var res = newSeq[MinValue](0)
    for c in countdown(q.qVal.len-1, 0):
      res.add q.qVal[c]
    i.push res.newVal

  def.symbol("filter") do (i: In):
    let vals = i.expect("quot", "quot")
    var filter = vals[0]
    let list = vals[1]
    var res = newSeq[MinValue](0)
    for e in list.qVal:
      i.push e
      i.dequote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == true:
        res.add e
    i.push res.newVal

  def.symbol("reject") do (i: In):
    let vals = i.expect("quot", "quot")
    var filter = vals[0]
    let list = vals[1]
    var res = newSeq[MinValue](0)
    for e in list.qVal:
      i.push e
      i.dequote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == false:
        res.add e
    i.push res.newVal

  def.symbol("any?") do (i: In):
    let vals = i.expect("quot", "quot")
    var filter = vals[0]
    let list = vals[1]
    var res = false.newVal
    for e in list.qVal:
      i.push e
      i.dequote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == true:
        res = true.newVal
        break
    i.push res

  def.symbol("one?") do (i: In):
    let vals = i.expect("quot", "quot")
    var filter = vals[0]
    let list = vals[1]
    var res = false.newVal
    for e in list.qVal:
      i.push e
      i.dequote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == true:
        if res == true.newVal:
          res = false.newVal
          break
        res = true.newVal
    i.push res

  def.symbol("all?") do (i: In):
    let vals = i.expect("quot", "quot")
    var filter = vals[0]
    let list = vals[1]
    var res = true.newVal
    for e in list.qVal:
      i.push e
      i.dequote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == false:
        res = false.newVal
        break
    i.push res

  def.symbol("sort") do (i: In):
    let vals = i.expect("quot", "quot")
    var cmp = vals[0]
    let list = vals[1]
    var i2 = i
    var minCmp = proc(a, b: MinValue): int {.closure.} =
      i2.push a
      i2.push b
      i2.dequote(cmp)
      let r = i2.pop
      if r.isBool:
        if r.isBool and r.boolVal == true:
          return 1
        else:
          return -1
      else:
        raiseInvalid("Predicate quotation must return a boolean value")
    var qList = list.qVal
    sort[MinValue](qList, minCmp)
    i.push qList.newVal

  def.symbol("shorten") do (i: In):
    let vals = i.expect("int", "quot")
    let n = vals[0]
    let q = vals[1]
    if n.intVal > q.qVal.len:
      raiseInvalid("Quotation is too short")
    i.push q.qVal[0..n.intVal.int-1].newVal

  def.symbol("take") do (i: In):
    let vals = i.expect("int", "quot")
    let n = vals[0]
    let q = vals[1]
    var nint = n.intVal
    if nint > q.qVal.len:
      nint = q.qVal.len
    i.push q.qVal[0..nint-1].newVal

  def.symbol("drop") do (i: In):
    let vals = i.expect("int", "quot")
    let n = vals[0]
    let q = vals[1]
    var nint = n.intVal
    if nint > q.qVal.len:
      nint = q.qVal.len
    i.push q.qVal[nint..q.qVal.len-1].newVal

  def.symbol("find") do (i: In):
    let vals = i.expect("quot", "quot")
    var test = vals[0]
    let s = vals[1]
    var result: MinValue
    var res = -1
    var c = 0
    for el in s.qVal:
      i.push el
      i.dequote test
      result = i.pop
      if result.isBool and result.boolVal == true:
        res = c
        break
      c.inc
    i.push res.newVal

  def.symbol("reduce") do (i: In):
    let vals = i.expect("quot", "a", "quot")
    var q = vals[0]
    var acc = vals[1]
    let s = vals[2]
    for el in s.qVal:
      i.push acc
      i.push el
      i.dequote q
      acc = i.pop
    i.push acc

  def.symbol("map-reduce") do (i: In):
    let vals = i.expect("quot", "quot", "quot")
    var red = vals[0]
    var map = vals[1]
    let s = vals[2]
    if s.qVal.len == 0:
      raiseInvalid("Quotation must have at least one element")
    i.push s.qVal[0]
    i.dequote map
    var acc = i.pop
    for ix in 1..s.qVal.len-1:
      i.push s.qVal[ix]
      i.dequote map
      i.push acc
      i.dequote red
      acc = i.pop
    i.push acc

  def.symbol("partition") do (i: In):
    let vals = i.expect("quot", "quot")
    var test = vals[0]
    var s = vals[1]
    var tseq = newSeq[MinValue](0)
    var fseq = newSeq[MinValue](0)
    for el in s.qVal:
      i.push el
      i.dequote test
      let res = i.pop
      if res.isBool and res.boolVal == true:
        tseq.add el
      else:
        fseq.add el
    i.push tseq.newVal
    i.push fseq.newVal

  def.symbol("slice") do (i: In):
    let vals = i.expect("int", "int", "quot")
    let finish = vals[0]
    let start = vals[1]
    let q = vals[2]
    let st = start.intVal
    let fn = finish.intVal
    if st < 0 or fn > q.qVal.len-1:
      raiseOutOfBounds("Index out of bounds")
    elif fn < st:
      raiseInvalid("End index must be greater than start index")
    let rng = q.qVal[st.int..fn.int]
    i.push rng.newVal

  def.symbol("harvest") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    var res = newSeq[MinValue](0)
    for el in q.qVal:
      if el.isQuotation and el.qVal.len == 0:
        continue
      res.add el
    i.push res.newVal

  def.symbol("flatten") do (i: In):
    let vals = i.expect("quot")
    let q = vals[0]
    var res = newSeq[MinValue](0)
    for el in q.qVal:
      if el.isQuotation:
        for el2 in el.qVal:
          res.add el2
      else:
        res.add el
    i.push res.newVal

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

  def.sigil("^") do (i: In):
    i.pushSym("lambda")

  def.sigil("~") do (i: In):
    i.pushSym("lambda-bind")

  def.sigil("$") do (i: In):
    i.pushSym("get-env")

  # Shorthand symbol aliases

  def.symbol("$") do (i: In):
    i.pushSym("get-env")

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

  def.finalize("global")
