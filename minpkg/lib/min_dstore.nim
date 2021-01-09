import
  json,
  strutils,
  oids
import
  ../core/parser,
  ../core/value,
  ../core/interpreter,
  ../core/utils

proc dstore_module*(i: In)=
  let def = i.define()

  def.symbol("dsinit") do (i: In):
    let vals = i.expect("'sym")
    let p = vals[0].getString
    p.writeFile("{}")
    var d = newDict(i.scope)
    i.dset(d, "data", newDict(i.scope))
    i.dset(d, "path", p.newVal)
    d.objType = "datastore"
    i.push d 

  def.symbol("dsread") do (i: In):
    let vals = i.expect("'sym")
    let p = vals[0].getString
    var j = p.readFile.parseJson 
    var d = newDict(i.scope)
    i.dset(d, "data", i.fromJson(j))
    i.dset(d, "path", p.newVal)
    d.objType = "datastore"
    i.push d 
  
  def.symbol("dswrite") do (i: In):
    let vals = i.expect("dict:datastore")
    let ds = vals[0]
    let p = i.dget(ds, "path".newVal).getString
    let data = i%(i.dget(ds, "data".newVal))
    p.writeFile(data.pretty)
    i.push ds
 
  def.symbol("dswrite!") do (i: In):
    i.pushSym "dswrite"
    i.pushSym "pop"
    
  def.symbol("dshas?") do (i: In):
    let vals = i.expect("'sym", "dict:datastore")
    let s = vals[0].getString
    let ds = vals[1]
    let parts = s.split("/")
    let collection = parts[0]
    let id = parts[1]
    let data = i.dget(ds, "data".newVal)
    if not dhas(data, collection):
      i.push false.newVal
    else:
      let cll = i.dget(data, collection.newVal)
      if dhas(cll, id.newVal):
        i.push true.newVal
      else:
        i.push false.newVal
      
  def.symbol("dsget") do (i: In):
    let vals = i.expect("'sym", "dict:datastore")
    let s = vals[0].getString
    let ds = vals[1]
    let parts = s.split("/")
    let collection = parts[0]
    let id = parts[1]
    let data = i.dget(ds, "data".newVal)
    if not dhas(data, collection):
      raiseInvalid("Collection '$#' does not exist" % collection)
    let cll = i.dget(data, collection)
    i.push i.dget(cll, id.newVal)
    
  def.symbol("dsquery") do (i: In):
    let vals = i.expect("quot", "'sym",  "dict:datastore")
    var filter = vals[0]
    let collection = vals[1]
    let ds = vals[2]
    let data = i.dget(ds, "data".newVal)
    var res = newSeq[MinValue](0)
    if not dhas(data, collection):
      i.push res.newVal
      return
    let cll = i.dget(data, collection)
    for e in i.values(cll).qVal:
      i.push e
      try:
        i.dequote(filter)
        var check = i.pop
        if check.isBool and check.boolVal == true:
          res.add e
      except:
        discard
    i.push res.newVal
      
  def.symbol("dspost") do (i: In):
    let vals = i.expect("dict", "'sym", "dict:datastore")
    var d = vals[0]
    let collection = vals[1]
    var ds = vals[2]
    let id = $genOid()
    i.dset(d, "id", id.newVal)
    var data = i.dget(ds, "data".newVal)
    if not dhas(data, collection):
      i.dset(data, collection, newDict(i.scope))
    var cll = i.dget(data, collection)
    i.dset(cll, id, d)
    i.push ds
    
  def.symbol("dspost!") do (i: In):
    i.pushSym "dspost"
    i.pushSym "pop"

  def.symbol("dsput") do (i: In):
    let vals = i.expect("dict", "'sym", "dict:datastore")
    var d = vals[0]
    let s = vals[1].getString
    let ds = vals[2]
    let parts = s.split("/")
    let collection = parts[0]
    if parts.len < 2:
      raiseInvalid("collection/id not specified")
    let id = parts[1]
    var data = i.dget(ds, "data".newVal)
    if not dhas(data, collection):
      i.dset(data, collection, newDict(i.scope))
    var cll = i.dget(data, collection)
    i.dset(cll, id, d)
    i.push ds
    
  def.symbol("dsput!") do (i: In):
    i.pushSym "dsput"
    i.pushSym "pop"
    
  def.symbol("dsdelete") do (i: In):
    let vals = i.expect("'sym", "dict:datastore")
    let s = vals[0].getString
    let ds = vals[1]
    let parts = s.split("/")
    if parts.len < 2:
      raiseInvalid("collection/id not specified")
    let collection = parts[0]
    let id = parts[1]
    var data = i.dget(ds, "data".newVal)
    if not dhas(data, collection):
      raiseInvalid("Collection '$#' does not exist" % collection)
    var cll = i.dget(data, collection)
    i.ddel(cll, id) 
    i.push ds
    
  def.symbol("dsdelete!") do (i: In):
    i.pushSym "dsdelete"
    i.pushSym "pop"
    
  def.finalize("dstore")
