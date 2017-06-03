import 
  critbits, 
  tables,
  sequtils,
  algorithm
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils
  
# Operations on sequences (data quotations)
proc seq_module*(i: In)=

  let def = i.define()

  def.symbol("concat") do (i: In):
    var q1, q2: MinValue 
    i.reqTwoQuotations q1, q2
    let q = q2.qVal & q1.qVal
    i.push q.newVal(i.scope)
  
  def.symbol("first") do (i: In):
    var q: MinValue
    i.reqQuotation q
    if q.qVal.len == 0:
      raiseOutOfBounds("Quotation is empty")
    i.push q.qVal[0]
  
  def.symbol("rest") do (i: In):
    var q: MinValue
    i.reqQuotation q
    if q.qVal.len == 0:
      raiseOutOfBounds("Quotation is empty")
    i.push q.qVal[1..q.qVal.len-1].newVal(i.scope)
  
  def.symbol("append") do (i: In):
    var q: MinValue
    i.reqQuotation q
    let v = i.pop
    i.push newVal(q.qVal & v, i.scope)
  
  def.symbol("prepend") do (i: In):
    var q: MinValue
    i.reqQuotation q
    let v = i.pop
    i.push newVal(v & q.qVal, i.scope)
  
  def.symbol("get") do (i: In):
    var index, q: MinValue
    i.reqIntAndQuotation index, q
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    i.push q.qVal[ix.int]
  
  def.symbol("set") do (i: In):
    var val, index, q: MinValue
    i.reqInt index
    val = i.pop
    i.reqQuotation q
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    q.qVal[ix.int] = val
    i.push q
  
  def.symbol("remove") do (i: In):
    var index, q: MinValue
    i.reqIntAndQuotation index, q
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    var res = newSeq[MinValue](0)
    for x in 0..q.qVal.len-1:
      if x == ix:
        continue
      res.add q.qVal[x]
    i.push res.newVal(i.scope)
  
  def.symbol("insert") do (i: In):
    var val, index, q: MinValue
    i.reqInt index
    val = i.pop
    i.reqQuotation q
    let ix = index.intVal
    if q.qVal.len < ix or ix < 0:
      raiseOutOfBounds("Index out of bounds")
    var res = newSeq[MinValue](0)
    for x in 0..q.qVal.len-1:
      if x == ix:
        res.add val
      res.add q.qVal[x]
    i.push res.newVal(i.scope)

  def.symbol("size") do (i: In):
    var q: MinValue
    i.reqQuotation q
    i.push q.qVal.len.newVal
  
  def.symbol("in?") do (i: In):
    i.reqStackSize(2)
    let v = i.pop
    var q: MinValue
    i.reqQuotation q
    i.push q.qVal.contains(v).newVal 
  
  def.symbol("map") do (i: In):
    var prog, list: MinValue
    i.reqTwoQuotations prog, list
    var res = newSeq[MinValue](0)
    for litem in list.qVal:
      i.push litem
      i.unquote(prog)
      res.add i.pop
    i.push res.newVal(i.scope)

  def.symbol("apply") do (i: In):
    var prog: MinValue
    i.reqQuotation prog
    i.apply prog

  def.symbol("reverse") do (i: In):
    var q: MinValue
    i.reqQuotation q
    var res = newSeq[MinValue](0)
    for c in countdown(q.qVal.len-1, 0):
      res.add q.qVal[c]
    i.push res.newVal(i.scope)

  def.symbol("filter") do (i: In):
    var filter, list: MinValue
    i.reqTwoQuotations filter, list
    var res = newSeq[MinValue](0)
    for e in list.qVal:
      i.push e
      i.unquote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == true:
        res.add e
    i.push res.newVal(i.scope)

  def.symbol("reject") do (i: In):
    var filter, list: MinValue
    i.reqTwoQuotations filter, list
    var res = newSeq[MinValue](0)
    for e in list.qVal:
      i.push e
      i.unquote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == false:
        res.add e
    i.push res.newVal(i.scope)

  def.symbol("any?") do (i: In):
    var filter, list: MinValue
    i.reqTwoQuotations filter, list
    for e in list.qVal:
      i.push e
      i.unquote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == true:
        i.push true.newVal
        return
    i.push false.newVal

  def.symbol("all?") do (i: In):
    var filter, list: MinValue
    i.reqTwoQuotations filter, list
    for e in list.qVal:
      i.push e
      i.unquote(filter)
      var check = i.pop
      if check.isBool and check.boolVal == false:
        i.push false.newVal
        break
    i.push true.newVal

  def.symbol("sort") do (i: In):
    var cmp, list: MinValue
    i.reqTwoQuotations cmp, list
    var i2 = i
    var minCmp = proc(a, b: MinValue): int {.closure.}=
      i2.push a
      i2.push b
      i2.unquote(cmp)
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
    i.push qList.newVal(i.scope)
  
  def.symbol("shorten") do (i: In):
    var n, q: MinValue
    i.reqIntAndQuotation n, q
    if n.intVal > q.qVal.len:
      raiseInvalid("Quotation is too short")
    i.push q.qVal[0..n.intVal.int-1].newVal(i.scope)

  def.symbol("find") do (i: In):
    var s, test, result: MinValue
    i.reqTwoQuotations test, s
    var res = -1
    var c = 0
    for el in s.qVal:
      i.push el
      i.unquote test
      result = i.pop
      if result.isBool and result.boolVal == true:
        res = c
        break
      c.inc
    i.push res.newVal

  def.symbol("reduce") do (i: In):
    var s, q, acc: MinValue
    i.reqQuotation q
    acc = i.pop
    i.reqQuotation s
    for el in s.qVal:
      i.push acc
      i.push el
      i.unquote q
      acc = i.pop
    i.push acc

  def.symbol("map-reduce") do (i: In):
    var s, map, red, acc: MinValue
    i.reqThreeQuotations red, map, s
    if s.qVal.len == 0:
      raiseInvalid("Quotation must have at least one element")
    i.push s.qVal[0]
    i.unquote map
    acc = i.pop
    for ix in 1..s.qVal.len-1:
      i.push s.qVal[ix]
      i.unquote map
      i.push acc
      i.unquote red
      acc = i.pop
    i.push acc

  def.symbol("partition") do (i: In):
    var s, test: MinValue
    i.reqTwoQuotations test, s
    var tseq = newSeq[MinValue](0)
    var fseq = newSeq[MinValue](0)
    for el in s.qVal:
      i.push el
      i.unquote test
      let res = i.pop
      if res.isBool and res.boolVal == true:
        tseq.add el
      else:
        fseq.add el
    i.push tseq.newVal(i.scope)
    i.push fseq.newVal(i.scope)

  def.symbol("slice") do (i: In):
    var start, finish, q: MinValue
    i.reqInt finish
    i.reqInt start
    i.reqQuotation q
    let st = start.intVal
    let fn = finish.intVal
    if st < 0 or fn > q.qVal.len-1:
      raiseOutOfBounds("Index out of bounds")
    elif fn < st:
      raiseInvalid("End index must be greater than start index")
    let rng = q.qVal[st.int..fn.int]
    i.push rng.newVal(i.scope)

  def.symbol("harvest") do (i: In):
    var q: MinValue
    i.reqQuotation q
    var res = newSeq[MinValue](0)
    for el in q.qVal:
      if el.isQuotation and el.qVal.len == 0:
        continue
      res.add el
    i.push res.newVal(i.scope)

  def.symbol("flatten") do (i: In):
    var q: MinValue
    i.reqQuotation q
    var res = newSeq[MinValue](0)
    for el in q.qVal:
      if el.isQuotation:
        for el2 in el.qVal:
          res.add el2
      else:
        res.add el
    i.push res.newVal(i.scope)

  # Operations on dictionaries

  def.symbol("dhas?") do (i: In):
    var d, k: MinValue
    i.reqStringLike k
    i.reqDictionary d
    i.push d.dhas(k).newVal

  def.symbol("dget") do (i: In):
    var d, k: MinValue
    i.reqStringLike k
    i.reqDictionary d
    i.push d.dget(k)
    
  def.symbol("dset") do (i: In):
    var d, k: MinValue
    i.reqStringLike k
    let m = i.pop
    i.reqDictionary d
    i.push i.dset(d, k, m) 

  def.symbol("ddel") do (i: In):
    var d, k: MinValue
    i.reqStringLike k
    i.reqDictionary d
    i.push i.ddel(d, k)

  def.symbol("keys") do (i: In):
    var d: MinValue
    i.reqDictionary d
    i.push i.keys(d)

  def.symbol("values") do (i: In):
    var d: MinValue
    i.reqDictionary d
    i.push i.values(d)

  

  def.finalize("seq")
