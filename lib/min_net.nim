import net, nativesockets, strutils
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# Net

proc toSocket(q: MinValue): Socket =
  return cast[Socket](q.obj)


proc net_module*(i: In)=
  let def = i.define()
  
  def.symbol("socket") do (i: In):
    let vals = i.expect "dict"
    var q = vals[0]
    var 
      domain = AF_INET
      sockettype = SOCK_STREAM
      protocol = IPPROTO_TCP
      sDomain = "ipv4"
      sSockType = "stream"
      sProtocol = "tcp"
    if q.dhas("domain"):
      sDomain = i.dget(q, "domain").getString
      if (sDomain == "unix"):
        domain = AF_UNIX
      elif (sDomain == "ipv6"):
        domain = AF_INET6
    if q.dhas("type"):
      sSockType = i.dget(q, "type").getString
      if (sSockType == "dgram"):
        sockettype = SOCK_DGRAM
      elif (sSockType == "raw"):
        sockettype = SOCK_RAW
      elif (sSockType == "seqpacket"):
        sockettype = SOCK_SEQPACKET
    if q.dhas("protocol"):
      sProtocol = i.dget(q, "protocol").getstring
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
    var skt = newDict(i.scope)
    skt = i.dset(skt, "domain", sDomain.newVal)
    skt = i.dset(skt, "type", sSockType.newVal)
    skt = i.dset(skt, "protocol", sProtocol.newVal)
    skt.objType = "socket"
    skt.obj = socket[].addr
    i.push skt

  def.symbol("close") do (i: In):
    let vals = i.expect("dict:socket")
    vals[0].toSocket.close()
 
  def.symbol("listen") do (i: In):
    let vals = i.expect("dict", "dict:socket")
    let params = vals[0]
    var skt = vals[1]
    var socket = skt.toSocket
    var address = "0.0.0.0"
    var port: BiggestInt = 80
    if params.dhas("address"):
      address = i.dget(params, "address").getString
    if params.dhas("port"):
      port = i.dget(params, "port").intVal
    socket.bindAddr(Port(port), address)
    skt = i.dset(skt, "address", address.newVal)
    skt = i.dset(skt, "port", port.newVal)
    skt.objType = "socket"
    skt.obj = socket[].addr
    socket.listen()
    i.push skt

  def.symbol("accept") do (i: In):
    let vals = i.expect("dict:socket", "dict:socket")
    var client = vals[0]
    var server = vals[1]
    var address = ""
    var serverSocket = server.toSocket
    var clientSocket = client.toSocket
    serverSocket.acceptAddr(clientSocket, address)
    i.dset(client, "address", address.newVal)
    client.objType = "socket"
    client.obj = clientSocket[].addr
    i.push client

  def.symbol("connect") do (i: In):
    let vals = i.expect("int", "string", "dict:socket")
    let port = vals[0]
    let address = vals[1]
    var skt = vals[2]
    let socket = skt.toSocket
    socket.connect(address.getString, Port(port.intVal))
    skt = i.dset(skt, "address", address)
    skt = i.dset(skt, "port", port)
    skt.objType = "socket"
    skt.obj = socket[].addr
    i.push skt

  def.symbol("send") do (i: In):
    let vals = i.expect("string", "dict:socket")
    let msg = vals[0]
    let skt = vals[1]
    skt.toSocket.send msg.getString

  def.symbol("recv") do (i: In):
    let vals = i.expect("int", "dict:socket")
    let size = vals[0]
    let skt = vals[1]
    var s = ""
    discard skt.toSocket.recv(s, size.intVal.int)
    i.push s.newVal

  def.symbol("recv-line") do (i: In):
    let vals = i.expect("dict:socket")
    let skt = vals[0]
    var s = skt.toSocket.recvLine()
    i.push s.newVal

  def.finalize("net")
