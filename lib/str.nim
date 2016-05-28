import tables, strutils
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils,
  ../core/regex

define("str")

  .symbol("split") do (i: In):
    let sep = i.pop
    let s = i.pop
    if s.isString and sep.isString:
      for e in s.strVal.split(sep.strVal):
        i.push e.newVal
    else:
      i.error errIncorrect, "Two strings are required on the stack"

  .symbol("search") do (i: In):
    let reg = i.pop
    let str = i.pop
    if str.isString and reg.isString:
      var matches = str.strVal.search(reg.strVal)
      var res = newSeq[MinValue](matches.len)
      for i in 0..matches.len-1:
        res[i] = matches[i].newVal
      i.push res.newVal
    else:
      i.error(errIncorrect, "Two strings are required on the stack")

  .symbol("match") do (i: In):
    let reg = i.pop
    let str = i.pop
    if str.isString and reg.isString:
      if str.strVal.match(reg.strVal):
        i.push true.newVal
      else:
        i.push false.newVal
    else:
      i.error(errIncorrect, "Two strings are required on the stack")

  .symbol("replace") do (i: In):
    let s_replace = i.pop
    let reg = i.pop
    let s_find = i.pop
    if reg.isString and s_replace.isString and s_find.isString:
      i.push regex.replace(s_find.strVal, reg.strVal, s_replace.strVal).newVal
    else:
      i.error(errIncorrect, "Three strings are required on the stack")

  .symbol("=~") do (i: In):
    let reg = i.pop
    let str = i.pop
    if str.isString and reg.isString:
      let results = str.strVal =~ reg.strVal
      var res = newSeq[MinValue](0)
      for r in results:
        res.add(r.newVal)
      i.push res.newVal
    else:
      i.error(errIncorrect, "Two strings are required on the stack")


  .finalize()
