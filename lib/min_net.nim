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
    # ((domain ipv4) (type stream) (protocol tcp))
    var 
      domain = AF_INET
      sockettype = SOCK_STREAM
      protocol = IPPROTO_TCP
      sDomain = "ipv4"
      sSockType = "stream"
      sProtocol = "tcp"
    if q.dhas("domain".newVal):
      sDomain = q.dget("domain".newVal).getString
      if (sDomain == "unix"):
        domain = AF_UNIX
      elif (sDomain == "ipv6"):
        domain = AF_INET6
    if q.dhas("type".newVal):
      sSockType = q.dget("type".newVal).getString
      if (sSockType == "dgram"):
        sockettype = SOCK_DGRAM
      elif (sSockType == "raw"):
        sockettype = SOCK_RAW
      elif (sSockType == "seqpacket"):
        sockettype = SOCK_SEQPACKET
    if q.dhas("protocol".newVal):
      sProtocol = q.dget("protocol".newVal).getstring
      if (sProtocol == "udp"):
        protocol = IPPROTO_UDP
      elif (sProtocol == "ipv4"):
        protocol = IPPROTO_IP
      elif (sProtocol == "ipv6"):
        protocol = IPPROTO_IPV6
      elif (sProtocol == "raw"):
        protocol = IPPROTO_RAW
      elif (sProtocol == "icmp"):
        protocol = IPPROTO_ICMP
    var socket = newSocket(domain, sockettype, protocol)
    var skt = newSeq[MinValue](0).newVal(i.scope)
    skt = i.dset(skt, "domain".newSym, sDomain.newVal)
    skt = i.dset(skt, "type".newSym, sSockType.newVal)
    skt = i.dset(skt, "protocol".newSym, sProtocol.newVal)
    skt.objType = "socket"
    skt.obj = socket[].addr
    i.push skt
 
  def.finalize("net")
