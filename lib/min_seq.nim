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

  i.define()

    .symbol("concat") do (i: In):
      var q1, q2: MinValue 
      i.reqTwoQuotations q1, q2
      let q = q2.qVal & q1.qVal
      i.push q.newVal(i.scope)
  
    .symbol("first") do (i: In):
      var q: MinValue
      i.reqQuotation q
      if q.qVal.len == 0:
        raiseOutOfBounds("Quotation is empty")
      i.push q.qVal[0]
  
    .symbol("rest") do (i: In):
      var q: MinValue
      i.reqQuotation q
      if q.qVal.len == 0:
        raiseOutOfBounds("Quotation is empty")
      i.push q.qVal[1..q.qVal.len-1].newVal(i.scope)
  
    .symbol("append") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.push newVal(q.qVal & v, i.scope)
    
    .symbol("prepend") do (i: In):
      var q: MinValue
      i.reqQuotation q
      let v = i.pop
      i.push newVal(v & q.qVal, i.scope)
    
    .symbol("at") do (i: In):
      var index, q: MinValue
      i.reqIntAndQuotation index, q
      if q.qVal.len-1 < index.intVal:
        raiseOutOfBounds("Insufficient items in quotation")
      i.push q.qVal[index.intVal.int]
  
    .symbol("size") do (i: In):
      var q: MinValue
      i.reqQuotation q
      i.push q.qVal.len.newVal
  
    .symbol("in?") do (i: In):
      i.reqStackSize(2)
      let v = i.pop
      var q: MinValue
      i.reqQuotation q
      i.push q.qVal.contains(v).newVal 
    
    .symbol("map") do (i: In):
      var prog, list: MinValue
      i.reqTwoQuotations prog, list
      var res = newSeq[MinValue](0)
      for litem in list.qVal:
        i.push litem
        i.unquote(prog)
        res.add i.pop
      i.push res.newVal(i.scope)

    .symbol("apply") do (i: In):
      var prog: MinValue
      i.reqQuotation prog
      i.apply prog

    .symbol("reverse") do (i: In):
      var q: MinValue
      i.reqQuotation q
      var res = newSeq[MinValue](0)
      for c in countdown(q.qVal.len-1, 0):
        res.add q.qVal[c]
      i.push res.newVal(i.scope)

    .symbol("filter") do (i: In):
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

    .symbol("any?") do (i: In):
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

    .symbol("all?") do (i: In):
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

    .symbol("sort") do (i: In):
      var cmp, list: MinValue
      i.reqTwoQuotations cmp, list
      var i2 = i
      var minCmp = proc(a, b: MinValue): int {.closure.}=
        i2.push a
        i2.push b
        i2.unquote(cmp)
        let r = i2.pop
        if r.isBool:
          if r.boolVal == true:
            return 1
          else:
            return -1
        else:
          raiseInvalid("Predicate quotation must return a boolean value")
      var qList = list.qVal
      sort[MinValue](qList, minCmp)
      i.push qList.newVal(i.scope)
    
    .symbol("shorten") do (i: In):
      var n, q: MinValue
      i.reqIntAndQuotation n, q
      if n.intVal > q.qVal.len:
        raiseInvalid("Quotation is too short")
      i.push q.qVal[0..n.intVal.int-1].newVal(i.scope)

    # Operations on dictionaries

    .symbol("dhas?") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push d.dhas(k).newVal

    .symbol("dget") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push d.dget(k)
      
    .symbol("dset") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      let m = i.pop
      i.reqDictionary d
      i.push i.dset(d, k, m) 

    .symbol("ddel") do (i: In):
      var d, k: MinValue
      i.reqStringLike k
      i.reqDictionary d
      i.push i.ddel(d, k)

    .symbol("keys") do (i: In):
      var d: MinValue
      i.reqDictionary d
      i.push i.keys(d)

    .symbol("values") do (i: In):
      var d: MinValue
      i.reqDictionary d
      i.push i.values(d)

    

    .finalize("seq")
