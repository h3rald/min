import strutils, critbits
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils,
  ../core/server

# I/O 


proc comm_module*(i: In) =
  i.define("comm")
    
    .symbol("reg") do (i: In):
      var host, address: MinValue
      i.reqTwoStringLike(host, address)
      i.link.hosts[host.getString] = address.getString
      for host, response in i.syncHosts().pairs:
        echo host, ": ", response
    
    .symbol("set-hosts") do (i: In):
      var q: MinValue
      i.reqQuotation(q)
      for pair in q.qVal:
        let vals = pair.qVal
        if not pair.isQuotation or vals.len != 2 or not vals[0].isStringLike or not vals[1].isStringLike:
          raiseInvalid("Invalid host quotation")
        i.link.hosts[vals[0].getString] = vals[1].getString
      i.push("OK".newVal)

    .symbol("hosts") do (i: In):
      var q = newSeq[MinValue](0).newVal
      for key, val in i.link.hosts.pairs:
        q.qVal.add(@[key.newSym, val.newSym].newVal)
      i.push q

    .symbol("host") do (i: In):
      i.push i.link.name.newVal

    .finalize()
