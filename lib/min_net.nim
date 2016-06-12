import net, nativesockets
import 
  ../core/types,
  ../core/parser,
  ../core/interpreter, 
  ../core/utils

# Network

define("net")

  .symbol("open") do (i: In):
    echo "all good"
    var q: MinValue
    i.reqQuotation q
    # (ipv4 stream tcp)
    if q.qVal.len < 3 or not (q.qVal[0].isSymbol and q.qVal[1].isSymbol and q.qVal[2].isSymbol):
      raiseInvalid("Quotation must contain three symbols for <domain> <type> <protocol>")
    let vals = q.qVal
    if not ["ipv4", "ipv6"].contains(vals[0].symVal):
      raiseInvalid("Domain symbol must be 'ipv4' or 'ipv6'")
    if not ["stream", "dgram"].contains(vals[1].symVal):
      raiseInvalid("Type symbol must be 'stream' or 'dgram'")
    if not ["tcp", "udp"].contains(vals[2].symVal):
      raiseInvalid("Protocol symbol must be 'tcp' or 'udp'")
    var 
      domain: Domain
      sockettype: SockType
      protocol: Protocol
    # Process domain
    if vals[0].symVal == "ipv4":
      domain = AF_INET
    else:
      domain = AF_INET6
    if vals[1].symVal == "stream":
      sockettype = SOCK_STREAM
    else:
      sockettype = SOCK_DGRAM
    if vals[2].symVal == "tcp":
      protocol = IPPROTO_TCP
    else:
      protocol = IPPROTO_UDP
    var socket = newSocket(domain, sockettype, protocol)
    echo "all good"
    q.objType = "socket"
    q.obj = socket.addr
    i.push @[q]
    

  .symbol("close") do (i: In):
    discard

  .symbol("listen") do (i: In):
    discard

  .symbol("accept") do (i: In):
    discard

  .symbol("connect") do (i: In):
    discard

  .symbol("send") do (i: In):
    discard

  .symbol("recv") do (i: In):
    discard

  .symbol("bind") do (i: In):
    discard

  .finalize()
