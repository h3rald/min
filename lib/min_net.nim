import net, nativesockets, strutils
import 
  ../core/types,
  ../core/parser,
  ../core/interpreter, 
  ../core/utils

# Network

define("net")

  .symbol("open-socket") do (i: In):
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
    q.objType = "socket"
    q.obj = socket[].addr
    i.push @[q]

  .symbol("tcp-socket") do (i: In):
    i.eval("(ipv4 stream tcp) net %open-socket")
    
  .symbol("udp-socket") do (i: In):
    i.eval("(ipv4 dgram udp) net %open-socket")

  .symbol("tcp6-socket") do (i: In):
    i.eval("(ipv6 stream tcp) net %open-socket")
    
  .symbol("udp6-socket") do (i: In):
    i.eval("(ipv6 dgram udp) net %open-socket")

  .symbol("close-socket") do (i: In):
    var q: MinValue
    i.reqObject "socket", q
    q.to(Socket).close()

  .symbol("listen") do (i: In):
    var port, q: MinValue
    i.reqInt port
    i.reqObject "socket", q
    var socket = q.to(Socket)
    socket.bindAddr(Port(port.intVal))
    q.qVal.add "0.0.0.0".newSym
    q.qVal.add port
    socket.listen()
    i.push @[q]

  .symbol("accept") do (i: In):
    var server: MinValue
    i.reqObject "socket", server
    # Open same socket type as server
    echo $server
    i.eval "$1 net %open-socket" % [$server.qVal[0..2].newVal]
    var clientVal: MinValue
    i.reqObject "socket", clientVal
    var client = clientVal.to(Socket)
    var address = ""
    server.to(Socket).acceptAddr(client, address)
    clientVal.qVal.add address.newSym
    i.push @[clientVal]

  .symbol("connect") do (i: In):
    var q, address, port: MinValue
    i.reqInt port
    i.reqString address
    i.reqObject "socket", q
    q.to(Socket).connect(address.strVal, Port(port.intVal))
    q.qVal.add address.strVal.newSym
    q.qVal.add port
    i.push @[q]

  .symbol("send") do (i: In):
    var q, s: MinValue
    i.reqString s
    i.reqObject "socket", q
    q.to(Socket).send s.strVal
    i.push @[q]


  .symbol("recv") do (i: In):
    var size, q: MinValue
    i.reqInt size
    i.reqObject "socket", q
    var s = ""
    discard q.to(Socket).recv(s, size.intVal)
    i.push @[q]
    i.push s.newVal

  .symbol("recv-line") do (i: In):
    var q: MinValue
    i.reqObject "socket", q
    var s = ""
    q.to(Socket).readLine(s)
    i.push @[q]
    i.push s.newVal

  .finalize()
