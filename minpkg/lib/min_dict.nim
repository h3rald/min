import
  std/critbits
import
  ../core/parser,
  ../core/value,
  ../core/interpreter,
  ../core/utils

proc dict_module*(i: In) =

  let def = i.define()

  def.symbol("dhas?") do (i: In):
    let vals = i.expect("'sym", "dict")
    let k = vals[0]
    let d = vals[1]
    i.push d.dhas(k).newVal

  def.symbol("dget") do (i: In):
    let vals = i.expect("'sym", "dict")
    let k = vals[0]
    let d = vals[1]
    i.push i.dget(d, k)

  def.symbol("dget-raw") do (i: In):
    let vals = i.expect("'sym", "dict")
    let k = vals[0]
    let d = vals[1]
    let v = i.dget(d, k)
    var rv = newDict(i.scope)
    rv.objType = "rawval"
    i.dset(rv, "type", v.typeName.newVal)
    i.dset(rv, "val", v)
    i.dset(rv, "str", newVal($v))
    i.push rv

  def.symbol("dset") do (i: In):
    let vals = i.expect("'sym", "a", "dict")
    let k = vals[0]
    let m = vals[1]
    var d = vals[2]
    i.push i.dset(d, k, m)

  def.symbol("dset-sym") do (i: In):
    let vals = i.expect("'sym", "'sym", "dict")
    let k = vals[0]
    let m = newSym(vals[1].getString)
    var d = vals[2]
    i.push i.dset(d, k, m)

  def.symbol("ddel") do (i: In):
    let vals = i.expect("'sym", "dict")
    let k = vals[0]
    var d = vals[1]
    i.push i.ddel(d, k)

  def.symbol("dkeys") do (i: In):
    let vals = i.expect("dict")
    let d = vals[0]
    i.push i.keys(d)

  def.symbol("dvalues") do (i: In):
    let vals = i.expect("dict")
    let d = vals[0]
    i.push i.values(d)

  def.symbol("dpairs") do (i: In):
    let vals = i.expect("dict")
    let d = vals[0]
    i.push i.pairs(d)

  def.symbol("ddup") do (i: In):
    let vals = i.expect("dict")
    let d = vals[0]
    var r = newDict(i.scope)
    for item in d.dVal.pairs:
      r.scope.symbols[item.key] = item.val
    i.push r

  def.symbol("dpick") do (i: In):
    let vals = i.expect("quot", "dict")
    var q = vals[0]
    var d = vals[1]
    var res = newDict(i.scope)
    for k in q.qVal:
      if d.dhas(k):
        i.dset(res, k, i.dget(d, k))
    i.push res

  def.symbol("dtype") do (i: In):
    let vals = i.expect("dict")
    i.push vals[0].objType.newVal

  def.sigil("/") do (i: In):
    i.pushSym("dget")

  def.sigil("%") do (i: In):
    i.pushSym("dset")

  def.finalize("dict")
