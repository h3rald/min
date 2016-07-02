import 
  asynchttpserver,
  asyncdispatch,
  httpclient,
  streams,
  critbits,
  pegs

import
  types,
  parser,
  interpreter,
  utils


proc validUrl(req: Request, url: string): bool =
  return req.url.path == url or req.url.path == url & "/"

proc validMethod(req: Request, meth: string): bool =
  return req.reqMethod == meth

proc reqPost(req: Request) {.async.}=
  if not req.validMethod("POST"):
    await req.respond(Http405, "Method Not Allowed: " & req.reqMethod)

#proc reqUrl(req: Request, url: string) {.async.}=
#  if not req.validUrl(url):
#    await req.respond(Http400, "Bad Request: POST " & req.url.path)


proc exec(req: Request, interpreter: MinInterpreter): string {.gcsafe.}=
  let filename = "request"
  let s = newStringStream(req.body)
  var i = interpreter
  i.open(s, filename)
  discard i.parser.getToken() 
  i.interpret()
  result = i.dump()
  i.close()

proc process(req: Request, i: MinInterpreter): string {.gcsafe.} =
  var matches = @["", "", ""]
  template route(req, peg: expr, op: stmt): stmt {.immediate.}=
    if req.url.path.find(peg, matches) != -1:
      op
  req.route peg"^\/exec\/?$":
    return exec(req, i)

proc serve*(port: Port, address = "", interpreter: MinInterpreter) =
  var hosts: CritBitTree[string]
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    if not req.validMethod("POST"):
      await req.respond(Http405, "Method Not Allowed: " & req.reqMethod)
    await req.respond(Http200, req.process(interpreter))
  let server = newAsyncHttpServer()
  asyncCheck server.serve(port, handleHttpRequest, address)

proc post*(url, content: string): string =
  url.postContent(content)

