import 
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
  return req.reqMethod == meth

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
  req.route peg"^\/exec\/?$":
    if not req.validMethod("POST"):
      raiseServer(Http405, "Method Not Allowed: " & req.reqMethod)
    return exec(req, i, hosts)
  raiseServer(Http400, "Bad Request: POST "& req.url.path)
  

proc serve*(port: Port, address = "", interpreter: MinInterpreter) =
  var hosts: CritBitTree[string]
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    var res: string
    var code: HttpCode = Http200
    try:
      res = req.process(interpreter, hosts)
    except MinServerError:
      let e: MinServerError = (MinServerError)getCurrentException()
      res = e.msg
      code = e.code
    await req.respond(code, res)
  let server = newAsyncHttpServer()
  asyncCheck server.serve(port, handleHttpRequest, address)

proc post*(url, content: string): string =
  url.postContent(content)

