import net, nativesockets
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# Time


proc net_module*(i: In)=
  let def = i.define()
  
  def.symbol("socket") do (i: In):
    let vals = i.expect "dict"
    var q = vals[0]
    # (ipv4 stream tcp)
    if q.qVal.len < 3 or not (q.qVal[0].isSymbol and q.qVal[1].isSymbol and q.qVal[2].isSymbol):
      raiseInvalid("Quotation must contain three symbols for <domain> <type> <protocol>")
    let values = q.qVal
    if not ["ipv4", "ipv6"].contains(values[0].symVal):
      raiseInvalid("Domain symbol must be 'ipv4' or 'ipv6'")
    if not ["stream", "dgram"].contains(values[1].symVal):
      raiseInvalid("Type symbol must be 'stream' or 'dgram'")
    if not ["tcp", "udp"].contains(values[2].symVal):
      raiseInvalid("Protocol symbol must be 'tcp' or 'udp'")
    var 
      domain: Domain
      sockettype: SockType
      protocol: Protocol
      sDomain, sSockType, sProtocol: string
    # Process domain
    if values[0].symVal == "ipv4":
      sDomain = "ipv4"
      domain = AF_INET
    else:
      sDomain = "ipv6"
      domain = AF_INET6
    if values[1].symVal == "stream":
      sSockType = "stream"
      sockettype = SOCK_STREAM
    else:
      sSockType = "dgram"
      sockettype = SOCK_DGRAM
    if values[2].symVal == "tcp":
      sProtocol = "tcp"
      protocol = IPPROTO_TCP
    else:
      sProtocol = "udp"
      protocol = IPPROTO_UDP
    var socket = newSocket(domain, sockettype, protocol)
    var skt = newSeq[MinValue](0).newVal(i.scope)
    i.dset(skt, "domain".newSym, sDomain.newVal)
    i.dset(skt, "type".newSym, sSockType.newVal)
    i.dset(skt, "protocol".newSym, sProtocol.newVal)
    skt.objType = "socket"
    skt.obj = socket[].addr
 
  def.finalize("net")
