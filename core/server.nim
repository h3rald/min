import 
  net,
  asynchttpserver,
  asyncdispatch,
  httpclient,
  streams,
  critbits,
  pegs,
  strutils

import
  types,
  parser,
  interpreter,
  utils


proc validUrl(req: Request, url: string): bool =
  return req.url.path == url or req.url.path == url & "/"

proc validMethod(req: Request, meth: string): bool =
  return req.reqMethod == meth or req.reqMethod == meth.toLower

proc exec(req: Request, interpreter: MinInterpreter, hosts: CritBitTree[string]): string {.gcsafe.}=
  let filename = "request"
  let s = newStringStream(req.body)
  var i = interpreter
  i.open(s, filename)
  discard i.parser.getToken() 
  i.interpret()
  result = i.dump()
  i.close()

proc process(req: Request, i: MinInterpreter, hosts: CritBitTree[string]): string {.gcsafe.} =
  var matches = @["", "", ""]
  template route(req, peg: expr, op: stmt): stmt {.immediate.}=
    if req.url.path.find(peg, matches) != -1:
      op
  req.route peg"^\/?$":
    if not req.validMethod("GET"):
      raiseServer(Http405, "Method Not Allowed: " & req.reqMethod)
    return "MiNiM Host '$1'" % [i.link.name]
  req.route peg"^\/exec\/?$":
    if not req.validMethod("POST"):
      raiseServer(Http405, "Method Not Allowed: " & req.reqMethod)
    return exec(req, i, hosts)
  raiseServer(Http400, "Bad Request: POST "& req.url.path)
  

proc init*(link: ref MinLink) {.thread.} =
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    var res: string
    var code: HttpCode = Http200
    try:
      res = req.process(link.interpreter, link.hosts)
    except MinServerError:
      let e: MinServerError = (MinServerError)getCurrentException()
      res = e.msg
      code = e.code
    await req.respond(code, res)
  asyncCheck link.server.serve(link.port, handleHttpRequest, link.address)

proc remoteExec*(i: MinInterpreter, host, content: string): string {.gcsafe.}=
  if i.link.hosts.hasKey(host):
    let url = "http://" & i.link.hosts[host] & "/exec"
    result = url.postContent(body = content, sslContext = nil)
  else:
    raiseServer(Http404, "Not Found: Host '$1'" % [host])

proc syncHosts*(i: MinInterpreter): CritBitTree[string] {.gcsafe.}=
  var cmd = ""
  for key, val in i.link.hosts.pairs:
    cmd = cmd & """ ($1 "$2")""" % [key, val] 
  cmd = "(" & cmd.strip & ") set-hosts"
  for key, val in i.link.hosts.pairs:
    if key != i.link.name:
      result[key] = i.remoteExec(key, cmd)

proc newMinLink*(name, address: string, port: int, i: var MinInterpreter): ref MinLink =
  var link: ref MinLink = new MinLink
  result = link
  result.server = newAsyncHttpServer()
  result.name = name
  result.address = address
  result.port = port.Port
  i.link = result
  result.interpreter = i
