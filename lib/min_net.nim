import net, nativesockets, strutils, critbits
import 
  ../core/types,
  ../core/parser,
  ../core/interpreter, 
  ../core/utils

# Network

proc net_module*(i: In)=

  i.define("net")
  
    .symbol("^socket") do (i: In):
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
      i.newScope("<socket>", q)
  
      q.scope
        .symbol("domain") do (i: In):
          i.push q
          i.push q.qVal[0].symVal.newVal
    
        .symbol("type") do (i: In):
          i.push q
          i.push q.qVal[1].symVal.newVal
    
        .symbol("protocol") do (i: In):
          i.push q
          i.push q.qVal[2].symVal.newVal
    
        .symbol("close") do (i: In):
          q.to(Socket).close()
    
        .symbol("listen") do (i: In):
          var port: MinValue
          i.reqInt port
          var socket = q.to(Socket)
          socket.bindAddr(Port(port.intVal))
          q.qVal.add "0.0.0.0".newSym
          q.qVal.add port
          q.scope
            .symbol("address") do (i:In):
              i.push "0.0.0.0".newVal
            .symbol("port") do (i:In):
              i.push port
            .finalize()
          socket.listen()
          i.push q
    
        .symbol("accept") do (i: In):
          # Open same socket type as server
          i.eval "$1 net %^socket" % [$q.qVal[0..2].newVal]
          var clientVal: MinValue
          i.reqObject "socket", clientVal
          var client = clientVal.to(Socket)
          var address = ""
          q.to(Socket).acceptAddr(client, address)
          clientVal.qVal.add address.newSym
          i.push clientVal
    
        .symbol("connect") do (i: In):
          var q, address, port: MinValue
          i.reqInt port
          i.reqString address
          q.to(Socket).connect(address.strVal, Port(port.intVal))
          q.qVal.add address.strVal.newSym
          q.qVal.add port
          q.scope
            .symbol("client-address") do (i:In):
              i.push address.strVal.newVal
            .symbol("client-port") do (i:In):
              i.push port
            .finalize()
          i.push q
    
        .symbol("send") do (i: In):
          var s: MinValue
          i.reqString s
          q.to(Socket).send s.strVal
          i.push q
    
        .symbol("recv") do (i: In):
          var size: MinValue
          i.reqInt size
          var s = ""
          discard q.to(Socket).recv(s, size.intVal.int)
          i.push q
          i.push s.newVal
    
        .symbol("recv-line") do (i: In):
          var s = ""
          q.to(Socket).readLine(s)
          i.push @[q]
          i.push s.newVal
    
        .finalize()
        
      i.push q
  
    .finalize()
