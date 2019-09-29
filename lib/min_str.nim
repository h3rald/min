import 
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
    let vals = i.expect("quot", "string")
    var q = vals[0]
    let s = vals[1]
    var strings = newSeq[string](0)
    for el in q.qVal:
      strings.add $$el
    let res = s.strVal % strings
    i.push res.newVal

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
    let sep = vals[0].getString
    let s = vals[1].getString
    var q = newSeq[MinValue](0)
    if (sep == ""):
      for c in s:
        q.add ($c).newVal
    else:
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

  def.symbol("titleize") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.split(" ").mapIt(it.capitalizeAscii).join(" ").newVal

  def.symbol("repeat") do (i: In):
    let vals = i.expect("int", "string")
    let n = vals[0]
    let s = vals[1]
    i.push s.getString.repeat(n.intVal).newVal

  def.symbol("indent") do (i: In):
    let vals = i.expect("int", "string")
    let n = vals[0]
    let s = vals[1]
    i.push s.getString.indent(n.intVal).newVal

  def.symbol("indexof") do (i: In):
    let vals = i.expect("string", "string")
    let reg = vals[0]
    let str = vals[1]
    let index = str.strVal.find(reg.strVal)
    i.push index.newVal

  def.symbol("search") do (i: In):
    let vals = i.expect("string", "string")
    let reg = vals[0]
    let str = vals[1]
    var matches = str.strVal.search(reg.strVal)
    var res = newSeq[MinValue](matches.len)
    for i in 0..matches.len-1:
      res[i] = matches[i].newVal
    i.push res.newVal

  def.symbol("match") do (i: In):
    let vals = i.expect("string", "string")
    let reg = vals[0]
    let str = vals[1]
    if str.strVal.match(reg.strVal):
      i.push true.newVal
    else:
      i.push false.newVal

  def.symbol("replace") do (i: In):
    let vals = i.expect("string", "string", "string")
    let s_replace = vals[0]
    let reg = vals[1]
    let s_find = vals[2]
    i.push sgregex.replace(s_find.strVal, reg.strVal, s_replace.strVal).newVal

  def.symbol("regex") do (i: In):
    let vals = i.expect("string", "string")
    let reg = vals[0]
    let str = vals[1]
    let results = str.strVal =~ reg.strVal
    var res = newSeq[MinValue](0)
    for r in results:
      res.add(r.newVal)
    i.push res.newVal

  def.symbol("=~") do (i: In):
    i.push("regex".newSym)

  def.symbol("%") do (i: In):
    i.push("interpolate".newSym)

  def.finalize("str")
