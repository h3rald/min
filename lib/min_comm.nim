import strutils, critbits, streams
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
      cfgSet("hosts", %i.link.hosts)

    .symbol("unreg") do (i: In):
      i.link.hosts.excl(i.link.name)
      for host, response in i.syncHosts().pairs:
        echo host, ": ", response
      cfgSet("hosts", %i.link.hosts)
    
    .symbol("set-hosts") do (i: In):
      var q: MinValue
      i.reqQuotation(q)
      for key, val in i.link.hosts.pairs:
        i.link.hosts.excl(key)
      for pair in q.qVal:
        let vals = pair.qVal
        if not pair.isQuotation or vals.len != 2 or not vals[0].isStringLike or not vals[1].isStringLike:
          raiseInvalid("Invalid host quotation")
        i.link.hosts.replace(vals[0].getString, vals[1].getString)
      cfgSet("hosts", %i.link.hosts)
      i.push(@["OK".newSym].newVal)

    .symbol("hosts") do (i: In):
      var q = newSeq[MinValue](0).newVal
      for key, val in i.link.hosts.pairs:
        q.qVal.add(@[key.newSym, val.newSym].newVal)
      i.push q

    .symbol("host") do (i: In):
      i.push i.link.name.newVal

    .symbol("to-host") do (i: In):
      var h, q: MinValue
      i.reqStringLikeAndQuotation(h, q)
      let host = h.getString
      i.eval i.executeOnHost(host, q)

    .symbol("to-all-hosts") do (i: In):
      var q: MinValue
      i.reqQuotation(q)
      var res = ""
      for host in i.link.hosts.keys:
        if host != i.link.name:
          res = res & " " & i.executeOnHost(host, q)
      i.eval("($1)" % res)

    .symbol("hostsync") do (i: In):
      var res = ""
      for key, value in i.syncHosts().pairs:
        res = res & " " & value
      i.eval "($1) dprint!" % res

    .finalize()
