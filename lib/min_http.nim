import httpclient, asynchttpserver, asyncdispatch, strutils, uri
import 
  ../core/parser, 
  ../core/consts,
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

let minUserAgent = "$1 http-module/$2" % [appname, version]

proc newCli(): HttpClient =
  return newHttpClient(userAgent = minUseragent)

proc newVal(i: In, headers: HttpHeaders): MinValue = 
  result = newVal(newSeq[MinValue](), i.scope)
  for k, v in headers:
    result = i.dset(result, k.newVal, v.newVal)

type MinServerExit = ref object of SystemError

# Http

proc http_module*(i: In)=
  let def = i.define()

  def.symbol("request") do (i: In):
    let vals = i.expect "dict"
    let req = vals[0]
    let cli = newCli()
    var body = "".newVal
    var rawHeaders, meth, url: MinValue
    var headers = newHttpHeaders()
    if not req.dhas("method".newVal):
      raiseInvalid("Request method not specified")
    if not req.dhas("url".newVal):
      raiseInvalid("Request URL not specified")
    if req.dhas("headers".newVal):
      rawHeaders = req.dget("headers".newVal)
      if not rawHeaders.isDictionary:
        raiseInvalid("Headers must be specified as a dictionary")
      for v in rawHeaders.qVal:
        headers[v.qVal[0].getString] = v.qVal[1].getString
    if req.dhas("body".newVal):
      body = req.dget("body".newVal)
    meth = req.dget("method".newVal)
    url = req.dget("url".newVal)
    let resp = cli.request(url = url.getString, httpMethod = meth.getString, body = body.getString, headers = headers)
    var res = newVal(newSeq[MinValue](), i.scope)
    res = i.dset(res, "version".newVal, resp.version.newVal)
    res = i.dset(res, "status".newVal, resp.status[0..2].parseInt.newVal)
    res = i.dset(res, "headers".newVal, i.newVal(resp.headers))
    res = i.dset(res, "body".newVal, resp.body.newVal)
    i.push res
  
  def.symbol("get-content") do (i: In):
    let vals = i.expect "string"
    let url = vals[0]
    let cli = newCli()
    i.push cli.getContent(url.getString).newVal

  def.symbol("download") do (i: In):
    let vals = i.expect("string", "string")
    let file = vals[0]
    let url = vals[1]
    let cli = newCli()
    cli.downloadFile(url.getString, file.getString)

  def.symbol("start-server") do (ii: In):
    let vals = ii.expect "dict"
    let cfg = vals[0]
    if not cfg.dhas("port".newVal):
      raiseInvalid("Port not specified.")
    if not cfg.dhas("handler".newVal):
      raiseInvalid("Handler quotation not specified.")
    let port = cfg.dget("port".newVal)
    var qhandler = cfg.dget("handler".newVal)
    var address = "".newVal
    if cfg.dhas("address".newVal):
      address = cfg.dget("address".newVal)
    if not qhandler.isQuotation:
      raiseInvalid("Handler is not a quotation.")
    if not port.isInt:
      raiseInvalid("Port is not an integer.")
    var server = newAsyncHttpServer()
    var i {.threadvar.}: MinInterpreter
    i = ii
    proc handler(req: Request) {.async, gcsafe.} =
      var qreq = newSeq[MinValue]().newVal(i.scope)
      qreq = i.dset(qreq, "url".newVal, newVal($req.url))
      qreq = i.dset(qreq, "headers".newVal, i.newVal(req.headers))
      qreq = i.dset(qreq, "method".newVal, newVal($req.reqMethod))
      qreq = i.dset(qreq, "hostname".newVal, newVal($req.hostname))
      qreq = i.dset(qreq, "version".newVal, newVal("$1.$2" % [$req.protocol.major, $req.protocol.minor]))
      qreq = i.dset(qreq, "body".newVal, newVal($req.body))
      i.push qreq
      i.dequote qhandler
      let qres = i.pop
      var body = "".newVal
      var rawHeaders = newSeq[MinValue]().newVal(i.scope)
      var v = "1.1".newVal
      var status = 200.newVal
      if not qres.isDictionary():
        raiseInvalid("Response is not a dictionary.")
      if qres.dhas("status".newVal):
        status = qres.dget("status".newVal)
      if not status.isInt and status.intVal < 600:
        raiseInvalid("Invalid status code: $1." % $status)
      if qres.dhas("body".newVal):
        body = qres.dget("body".newVal)
      if not body.isString:
        raiseInvalid("Response body is not a string.")
      if qres.dhas("version".newVal):
        v = qres.dget("version".newVal)
      if qres.dhas("headers".newVal):
        rawHeaders = qres.dget("headers".newVal)
      if not rawHeaders.isDictionary():
        raiseInvalid("Response headers are not in a dictionary.")
      var headers = newHttpHeaders()
      for v in rawHeaders.qVal:
        headers[v.qVal[0].getString] = v.qVal[1].getString
      await req.respond(status.intVal.HttpCode, body.getString, headers)
    try:
      waitFor server.serve(port = port.intVal.Port, callback = handler, address = address.getString)
    except MinServerExit:
      server.close()

  def.symbol("stop-server") do (i: In):
    raise MinServerExit()
    

  def.finalize("http")
