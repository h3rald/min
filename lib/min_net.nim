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
        sDomain, sSockType, sProtocol: string
      # Process domain
      if vals[0].symVal == "ipv4":
        sDomain = "ipv4"
        domain = AF_INET
      else:
        sDomain = "ipv6"
        domain = AF_INET6
      if vals[1].symVal == "stream":
        sSockType = "stream"
        sockettype = SOCK_STREAM
      else:
        sSockType = "dgram"
        sockettype = SOCK_DGRAM
      if vals[2].symVal == "tcp":
        sProtocol = "tcp"
        protocol = IPPROTO_TCP
      else:
        sProtocol = "udp"
        protocol = IPPROTO_UDP
      var socket = newSocket(domain, sockettype, protocol)
      var qs = @[
        @["domain".newSym, sDomain.newVal].newVal, 
        @["type".newSym, sSockType.newVal].newVal,
        @["protocol".newSym, sProtocol.newVal].newVal
      ].newVal
      qs.objType = "socket"
      qs.obj = socket[].addr
      i.newScope("<socket>", qs)

      var sAddress: string
      var sPort: BiggestInt
  
      qs.scope
        .symbol("close") do (i: In):
          qs.to(Socket).close()
    
        .symbol("listen") do (i: In):
          var port: MinValue
          i.reqInt port
          var socket = qs.to(Socket)
          sAddress = "0.0.0.0"
          sPort = port.intVal
          socket.bindAddr(Port(sPort))
          qs.qVal.add @["address".newSym, sAddress.newVal].newVal
          qs.qVal.add @["port".newSym, sPort.newVal].newVal
          socket.listen()
          i.push qs
    
        .symbol("accept") do (i: In):
          # Open same socket type as server
          i.eval "($1 $2 $3) net %^socket" % [sDomain, sSockType, sProtocol]
          var clientVal: MinValue
          i.reqObject "socket", clientVal
          var client = clientVal.to(Socket)
          var address = ""
          qs.to(Socket).acceptAddr(client, address)
          clientVal.qVal.add address.newSym
          i.push clientVal
    
        .symbol("connect") do (i: In):
          var address, port: MinValue
          i.reqInt port
          i.reqStringLike address
          qs.to(Socket).connect(address.strVal, Port(port.intVal))
          #var qc = @[
          #  @["domain".newSym, sDomain.newVal].newVal, 
          #  @["type".newSym, sSockType.newVal].newVal, 
          #  @["protocol".newSym, sProtocol.newVal].newVal
          #].newVal
          qs.qVal.add @["address".newSym, address.getString.newVal].newVal
          qs.qVal.add @["port".newSym, port].newVal
          i.push qs
    
        .symbol("send") do (i: In):
          echo "sending"
          var s: MinValue
          i.reqString s
          qs.to(Socket).send s.strVal
          i.push qs
    
        .symbol("recv") do (i: In):
          var size: MinValue
          i.reqInt size
          var s = ""
          discard qs.to(Socket).recv(s, size.intVal.int)
          i.push qs
          i.push s.newVal
    
        .symbol("recv-line") do (i: In):
          var s = ""
          qs.to(Socket).readLine(s)
          i.push @[qs]
          i.push s.newVal
    
        .finalize()
        
      i.push qs
  
    .finalize()
