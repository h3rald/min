import net, nativesockets, strutils, critbits
import 
  ../core/types,
  ../core/parser,
  ../core/interpreter, 
  ../core/utils

# Network

var symbols*: CritBitTree[proc(obj: Val, i: In): MinOperator]

proc socketSymbol(name: string, body: proc(q: Val, i: In))=
  symbols[name] = proc(obj: Val, i: In): MinOperator = 
    i.localSymbol(obj, "socket") do (i: In):
      var q: MinValue
      i.reqObject "socket", q
      q.body(i)

socketSymbol("domain") do (q: Val, i: In):
  i.push q
  i.push q.qVal[0].symVal.newVal

socketSymbol("type") do (q: Val, i: In):
  i.push q
  i.push q.qVal[1].symVal.newVal

socketSymbol("protocol") do (q: Val, i: In):
  i.push q
  i.push q.qVal[2].symVal.newVal

socketSymbol("close") do (q: Val, i: In):
  q.to(Socket).close()

socketSymbol("listen") do (q: Val, i: In):
  var port: MinValue
  i.reqInt port
  var socket = q.to(Socket)
  socket.bindAddr(Port(port.intVal))
  q.qVal.add "0.0.0.0".newSym
  q.qVal.add port
  q.scope.symbols["address"] = proc (i:In) =
    i.push "0.0.0.0".newVal
  q.scope.symbols["port"] = proc (i:In) =
    i.push port
  socket.listen()
  i.push q

socketSymbol("accept") do (q: Val, i: In):
  # Open same socket type as server
  i.eval "$1 net %^socket" % [$q.qVal[0..2].newVal]
  var clientVal: MinValue
  i.reqObject "socket", clientVal
  var client = clientVal.to(Socket)
  var address = ""
  q.to(Socket).acceptAddr(client, address)
  clientVal.qVal.add address.newSym
  i.push clientVal

socketSymbol("connect") do (q: Val, i: In):
  var q, address, port: MinValue
  i.reqInt port
  i.reqString address
  q.to(Socket).connect(address.strVal, Port(port.intVal))
  q.qVal.add address.strVal.newSym
  q.qVal.add port
  q.scope.symbols["client-address"] = proc (i:In) =
    i.push address.strVal.newVal
  q.scope.symbols["client-port"] = proc (i:In) =
    i.push port
  i.push q

socketSymbol("send") do (q: Val, i: In):
  var s: MinValue
  i.reqString s
  q.to(Socket).send s.strVal
  i.push q

socketSymbol("recv") do (q: Val, i: In):
  var size: MinValue
  i.reqInt size
  var s = ""
  discard q.to(Socket).recv(s, size.intVal.int)
  i.push q
  i.push s.newVal
  
socketSymbol("recv-line") do (q: Val, i: In):
  var s = ""
  q.to(Socket).readLine(s)
  i.push @[q]
  i.push s.newVal

define("net")

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
    q.scope.symbols["domain"] = symbols["domain"](q, i)
    q.scope.symbols["type"] = symbols["type"](q, i)
    q.scope.symbols["protocol"] = symbols["protocol"](q, i)
    q.scope.symbols["close"] = symbols["close"](q, i)
    q.scope.symbols["listen"] = symbols["listen"](q, i)
    q.scope.symbols["accept"] = symbols["accept"](q, i)
    q.scope.symbols["connect"] = symbols["connect"](q, i)
    q.scope.symbols["send"] = symbols["send"](q, i)
    q.scope.symbols["recv"] = symbols["recv"](q, i)
    q.scope.symbols["recv-line"] = symbols["recv-line"](q, i)
    i.push q

  .finalize()
