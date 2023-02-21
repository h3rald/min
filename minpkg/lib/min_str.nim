import 
  strutils, 
  sequtils,
  nre,
  uri
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/baseutils,
  ../core/utils

proc str_module*(i: In) = 
  let def = i.define()

  when defined(windows): 
    {.passL: "-static -Lminpkg/vendor/pcre/windows -lpcre".}
  elif defined(linux):
    {.passL: "-static -Lminpkg/vendor/pcre/linux -lpcre".}
  elif defined(macosx):
    {.passL: "-Bstatic -Lminpkg/vendor/pcre/macosx -lpcre -Bdynamic".}

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
    let repFn = proc(match: RegexMatch): string =
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

  def.symbol("%") do (i: In):
    i.pushSym("interpolate")

  def.symbol("=%") do (i: In):
    i.pushSym("apply-interpolate")

  def.finalize("str")
