import 
  tables, 
  strutils, 
  sequtils
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils,
  ../packages/nim-sgregex/sgregex


proc str_module*(i: In) = 
  let def = i.define()

  def.symbol("interpolate") do (i: In):
    var s, q: MinValue
    i.reqQuotationAndString q, s
    var strings = newSeq[string](0)
    for el in q.qVal:
      strings.add $$el
    let res = s.strVal % strings
    i.push res.newVal

  def.symbol("strip") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.strip.newVal
    
  def.symbol("split") do (i: In):
    var sep, s: MinValue
    i.reqTwoStrings sep, s
    var q = newSeq[MinValue](0)
    for e in s.strVal.split(sep.strVal):
      q.add e.newVal
    i.push q.newVal(i.scope)

  def.symbol("join") do (i: In):
    var q, s: MinValue
    i.reqStringLikeAndQuotation s, q
    i.push q.qVal.mapIt($$it).join(s.getString).newVal 

  def.symbol("length") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.len.newVal
  
  def.symbol("lowercase") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.toLowerAscii.newVal

  def.symbol("uppercase") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.toUpperAscii.newVal

  def.symbol("capitalize") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.capitalizeAscii.newVal

  def.symbol("titleize") do (i: In):
    var s: MinValue
    i.reqStringLike s
    i.push s.getString.split(" ").mapIt(it.capitalizeAscii).join(" ").newVal

  def.symbol("repeat") do (i: In):
    var s, n: MinValue
    i.reqIntAndString n, s
    i.push s.getString.repeat(n.intVal).newVal

  def.symbol("indent") do (i: In):
    var s, n: MinValue
    i.reqIntAndString n, s
    i.push s.getString.indent(n.intVal).newVal

  def.symbol("string") do (i: In):
    var s = i.pop
    i.push(($$s).newVal)

  def.symbol("bool") do (i: In):
    var v = i.pop
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
    var s = i.pop
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
    var s = i.pop
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

  def.symbol("search") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    var matches = str.strVal.search(reg.strVal)
    var res = newSeq[MinValue](matches.len)
    for i in 0..matches.len-1:
      res[i] = matches[i].newVal
    i.push res.newVal(i.scope)

  def.symbol("match") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    if str.strVal.match(reg.strVal):
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("replace") do (i: In):
    var s_replace, reg, s_find: MinValue
    i.reqThreeStrings s_replace, reg, s_find
    i.push sgregex.replace(s_find.strVal, reg.strVal, s_replace.strVal).newVal

  def.symbol("regex") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    let results = str.strVal =~ reg.strVal
    var res = newSeq[MinValue](0)
    for r in results:
      res.add(r.newVal)
    i.push res.newVal(i.scope)

  def.symbol("=~") do (i: In):
    i.push("regex".newSym)

  def.symbol("%") do (i: In):
    i.push("interpolate".newSym)

  def.finalize("str")
