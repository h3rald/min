import 
  std/macros,
  httpclient, 
  asynchttpserver, 
  asyncdispatch, 
  strutils, 
  uri, 
  critbits
import 
  ../core/parser, 
  ../core/meta,
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

when defined(ssl) and defined(amd64):
  when defined(windows): 
    {.passL: "-static -L"&getProjectPath()&"/minpkg/vendor/openssl/windows -lssl -lcrypto -lws2_32".}
  elif defined(linux):
    {.passL: "-static -L"&getProjectPath()&"/minpkg/vendor/openssl/linux -lssl -lcrypto".}
  elif defined(macosx):
    {.passL: "-Bstatic -L"&getProjectPath()&"/minpkg/vendor/openssl/macosx -lssl -lcrypto -Bdynamic".}

var minUserAgent {.threadvar.} : string
minUserAgent = "$1 http-module/$2" % [pkgName, pkgVersion]

proc newCli(): HttpClient =
  return newHttpClient(userAgent = minUseragent)

proc newVal(i: In, headers: HttpHeaders): MinValue = 
  result = newDict(i.scope)
  for k, v in headers:
    result = i.dset(result, k, v.newVal)

type MinServerExit = ref object of CatchableError 

proc http_module*(i: In)=
  let def = i.define()

  def.symbol("request") do (i: In) :
    let vals = i.expect "dict"
    let req = vals[0]
    let cli = newCli()
    var body = "".newVal
    var rawHeaders, meth, url: MinValue
    var headers = newHttpHeaders()
    if not req.dhas("method"):
      raiseInvalid("Request method not specified")
    if not req.dhas("url"):
      raiseInvalid("Request URL not specified")
    if req.dhas("headers"):
      rawHeaders = i.dget(req, "headers")
      if not rawHeaders.isDictionary:
        raiseInvalid("Headers must be specified as a dictionary")
      for item in rawHeaders.dVal.pairs:
        headers[item.key] = i.dget(rawHeaders, item.key).getString
    if req.dhas("body"):
      body = i.dget(req, "body")
    meth = i.dget(req, "method")
    url = i.dget(req, "url")
    let resp = cli.request(url = url.getString, httpMethod = parseEnum[HttpMethod](meth.getString), body = body.getString, headers = headers)
    var res = newDict(i.scope)
    res.objType = "http-response"
    res = i.dset(res, "version", resp.version.newVal)
    res = i.dset(res, "status", resp.status[0..2].parseInt.newVal)
    res = i.dset(res, "headers", i.newVal(resp.headers))
    var b = ""
    if resp.status != $Http204:
      b = resp.body
    res = i.dset(res, "body", b.newVal)
    i.push res
  
  def.symbol("get-content") do (i: In):
    let vals = i.expect "str"
    let url = vals[0]
    let cli = newCli()
    i.push cli.getContent(url.getString).newVal

  def.symbol("download") do (i: In):
    let vals = i.expect("str", "str")
    let file = vals[0]
    let url = vals[1]
    let cli = newCli()
    cli.downloadFile(url.getString, file.getString)

  def.symbol("start-server") do (ii: In) :
    let vals = ii.expect "dict"
    let cfg = vals[0]
    if not cfg.dhas("port"):
      raiseInvalid("Port not specified.")
    if not cfg.dhas("handler"):
      raiseInvalid("Handler quotation not specified.")
    let port = ii.dget(cfg, "port")
    var qhandler = ii.dget(cfg, "handler")
    var address = "".newVal
    if cfg.dhas("address"):
      address = ii.dget(cfg, "address")
    if not qhandler.isQuotation:
      raiseInvalid("Handler is not a quotation.")
    if not port.isInt:
      raiseInvalid("Port is not an integer.")
    var server = newAsyncHttpServer()
    var i {.threadvar.}: MinInterpreter
    i = ii.copy(ii.filename)
    proc handler(req: Request) {.async, gcsafe.} =
      var qreq = newDict(i.scope)
      qreq.objType = "http-request"
      qreq = i.dset(qreq, "url", newVal($req.url))
      qreq = i.dset(qreq, "headers", i.newVal(req.headers))
      qreq = i.dset(qreq, "method", newVal($req.reqMethod))
      qreq = i.dset(qreq, "hostname", newVal($req.hostname))
      qreq = i.dset(qreq, "version", newVal("$1.$2" % [$req.protocol.major, $req.protocol.minor]))
      qreq = i.dset(qreq, "body", newVal($req.body))
      i.handleErrors do:
        i.push qreq
        i.dequote qhandler
      let qres = i.pop
      var body = "".newVal
      var rawHeaders = newDict(i.scope)
      var v = "1.1"
      var status = 200.newVal
      if not qres.isDictionary():
        raiseInvalid("Response is not a dictionary.")
      if qres.dhas("status"):
        status = i.dget(qres, "status")
      if not status.isInt and status.intVal < 600:
        raiseInvalid("Invalid status code: $1." % $status)
      if qres.dhas("body"):
        body = i.dget(qres, "body")
      if not body.isString:
        raiseInvalid("Response body is not a string.")
      if qres.dhas("version"):
        v = i.dget(qres, "version").getString
      if qres.dhas("headers"):
        rawHeaders = i.dget(qres, "headers")
      if not rawHeaders.isDictionary():
        raiseInvalid("Response headers are not in a dictionary.")
      var headers = newHttpHeaders()
      for k in items(i.keys(rawHeaders).qVal):
        headers[k.getString] = i.dget(rawHeaders, k.getString).getString
      # clear stack
      while i.stack.len > 0:
        discard i.pop
      await req.respond(status.intVal.HttpCode, body.getString, headers)
    try:
      waitFor server.serve(port = port.intVal.Port, callback = handler, address = address.getString)
    except MinServerExit:
      server.close()

  def.symbol("stop-server") do (i: In):
    raise MinServerExit()

  def.finalize("http")
