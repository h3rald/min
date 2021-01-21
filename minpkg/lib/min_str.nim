import 
  strutils, 
  sequtils 
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/baseutils,
  ../core/utils

when not defined(mini):
  import 
    ../packages/nim-sgregex/sgregex,
    uri

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

  when not defined(mini):
  
    def.symbol("encode-url") do (i: In):
      let vals = i.expect("string")
      let s = vals[0].strVal
      i.push s.encodeUrl.newVal
      
    def.symbol("decode-url") do (i: In):
      let vals = i.expect("string")
      let s = vals[0].strVal
      i.push s.decodeUrl.newVal
      
    def.symbol("parse-url") do (i: In):
      let vals = i.expect("string")
      let s = vals[0].strVal
      let u = s.parseUri
      var d = newDict(i.scope)
      i.dset(d, "scheme", u.scheme.newVal)
      i.dset(d, "username", u.username.newVal)
      i.dset(d, "password", u.password.newVal)
      i.dset(d, "hostname", u.hostname.newVal)
      i.dset(d, "port", u.port.newVal)
      i.dset(d, "path", u.path.newVal)
      i.dset(d, "query", u.query.newVal)
      i.dset(d, "anchor", u.anchor.newVal)
      i.push d
  
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

    def.symbol("replace-apply") do (i: In):
      let vals = i.expect("quot", "string", "string")
      let q = vals[0]
      let reg = vals[1]
      let s_find = vals[2]
      var i2 = i.copy(i.filename)
      let repFn = proc(a: seq[string]): string =
        var ss = newSeq[MinValue](0)
        for s in a:
          ss.add s.newVal
        i2.push ss.newVal
        i2.push q
        i2.pushSym "dequote"
        return i2.pop.getString
      i.push sgregex.replacefn(s_find.strVal, reg.strVal, "", repFn).newVal

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

    def.symbol("semver?") do (i: In):
      let vals = i.expect("string")
      let v = vals[0].strVal
      i.push v.match("^\\d+\\.\\d+\\.\\d+$").newVal
      
    def.symbol("from-semver") do (i: In):
      let vals = i.expect("string")
      let v = vals[0].strVal
      let parts = v.search("^(\\d+)\\.(\\d+)\\.(\\d+)$")
      if parts[0].len == 0:
        raiseInvalid("String '$1' is not a basic semver" % v)
      var d = newDict(i.scope)
      i.dset(d, "major", parts[1].parseInt.newVal)
      i.dset(d, "minor", parts[2].parseInt.newVal)
      i.dset(d, "patch", parts[3].parseInt.newVal)
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

  def.symbol("=~") do (i: In):
    i.pushSym("regex")

  def.symbol("%") do (i: In):
    i.pushSym("interpolate")

  def.symbol("=%") do (i: In):
    i.pushSym("apply-interpolate")

  def.finalize("str")
