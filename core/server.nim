import
  json,
  strutils,
  logging,
  asyncdispatch,
  httpcore,
  asynchttpserver

import
  consts,
  jsonlogger,
  parser,
  value,
  interpreter,
  utils

let SRVADDRESS* = "127.0.0.1"
var SRVPORT* = 5555
var SRVINTERPRETER* {.threadvar.}: MinInterpreter

var SRVHEADERS {.threadvar}: array[0..2, (string, string)]
SRVHEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Server": pkgName & "/" & pkgVersion
}

when not defined(release):
  proc setOrigin*(req: Request, headers: var HttpHeaders) =
    var host = ""
    var port = ""
    var protocol = "http"
    headers["Vary"] = "Origin"
    if req.headers.hasKey("Origin"):
      headers["Access-Control-Allow-Origin"] = req.headers["Origin"]
      return
    elif req.url.hostname != "" and req.url.port != "":
      host = req.url.hostname
      port = req.url.port
    elif req.headers.hasKey("origin"):
      let parts = req.headers["origin"].split("://")
      protocol = parts[0]
      let server = parts[1].split(":")
      if (server.len >= 2):
        host = server[0]
        port = server[1]
      else:
        host = server[0]
        port = "80"
    else:
      headers["Access-Control-Allow-Origin"] = "*"
      return
    headers["Vary"] = "Origin"
    headers["Access-Control-Allow-Origin"] = "$1://$2:$3" % [protocol, host, port]

proc ctHeader*(ct: string): HttpHeaders =
  var h = newHttpHeaders(SRVHEADERS)
  h["Content-Type"] = ct
  return h

proc stdJsonHeaders*(req: Request): HttpHeaders =
  result = ctHeader("application/json")
  when not defined(release):
    req.setOrigin(result)

proc resError*(req: Request, code: HttpCode, message: string): Future[void] {.async.} =
  var content = newJObject()
  content["error"] = %message
  await req.respond(code, content.pretty, req.stdJsonHeaders())

proc jsonExecutionResult*(i: var MinInterpreter, r: MinValue): string =
  let j = newJObject()
  j["result"] = newJNull()
  if not r.isNil:
    j["result"] = i%r
  j["stack"] = i%(i.stack.newVal)
  j["output"] = JSONLOG
  return j.pretty
  
proc minApiExecHandler*(req: Request): Future[void] {.async.} =
  let j = req.body.parseJson
  var r: MinValue
  try:
    r = SRVINTERPRETER.interpret(j["data"].getStr)
  except:
    discard
  await req.respond(Http200, jsonExecutionResult(SRVINTERPRETER, r), req.stdJsonHeaders)

proc minServer*(address: string, port: int) = 
  notice "$# v$# API Server started on $#:$#" % [pkgName, pkgVersion, SRVADDRESS, $SRVPORT]
  notice "Press Ctrl+C to stop."
  proc handleHttpRequest(req: Request) {.async, gcsafe, closure.} =
    JSONLOG = newJArray()
    if req.url.path == "/api/run" and req.reqMethod == HttpPost:
      await minApiExecHandler(req)
    else:
      await req.resError(Http400, "Bad Request")
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(port), handleHttpRequest, address)
  runForever()