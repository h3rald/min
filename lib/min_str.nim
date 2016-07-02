import tables, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils,
  ../core/regex



proc str_module*(i: In) = 
  i.define("str")

  .symbol("split") do (i: In):
    var sep, s: MinValue
    i.reqTwoStrings sep, s
    var q = newSeq[MinValue](0)
    for e in s.strVal.split(sep.strVal):
      q.add e.newVal
    i.push q.newVal

  .symbol("search") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    var matches = str.strVal.search(reg.strVal)
    var res = newSeq[MinValue](matches.len)
    for i in 0..matches.len-1:
      res[i] = matches[i].newVal
    i.push res.newVal

  .symbol("match") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    if str.strVal.match(reg.strVal):
      i.push true.newVal
    else:
      i.push false.newVal

  .symbol("replace") do (i: In):
    var s_replace, reg, s_find: MinValue
    i.reqThreeStrings s_replace, reg, s_find
    i.push regex.replace(s_find.strVal, reg.strVal, s_replace.strVal).newVal

  .symbol("=~") do (i: In):
    var reg, str: MinValue
    i.reqTwoStrings reg, str
    let results = str.strVal =~ reg.strVal
    var res = newSeq[MinValue](0)
    for r in results:
      res.add(r.newVal)
    i.push res.newVal

  .finalize()
