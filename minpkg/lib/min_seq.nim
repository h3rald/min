import 
  tables,
  algorithm,
  sets,
  sequtils
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils
  
proc seq_module*(i: In)=

  let def = i.define()

  def.symbol("intersection") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = toHashSet(vals[0].qVal)
    let q2 = toHashSet(vals[1].qVal)
    i.push toSeq(items(q2.intersection(q1))).newVal 

  def.symbol("union") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = toHashSet(vals[0].qVal)
    let q2 = toHashSet(vals[1].qVal)
    i.push toSeq(items(q2.union(q1))).newVal 

  def.symbol("difference") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = toHashSet(vals[0].qVal)
    let q2 = toHashSet(vals[1].qVal)
    i.push toSeq(items(q2.difference(q1))).newVal 

  def.symbol("symmetric-difference") do (i: In):
    let vals = i.expect("quot", "quot")
    let q1 = toHashSet(vals[0].qVal)
    let q2 = toHashSet(vals[1].qVal)
    i.push toSeq(items(q2.symmetricDifference(q1))).newVal 

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
    var minCmp = proc(a, b: MinValue): int {.closure.}=
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

  def.finalize("seq")
