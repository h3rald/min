import httpclient, strutils
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
    i.dset(result, k.newVal, v.newVal)

proc execRequest(i:In, req: MinValue): MinValue = 
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
  result = newVal(newSeq[MinValue](), i.scope)
  result = i.dset(result, "version".newVal, resp.version.newVal)
  result = i.dset(result, "status".newVal, resp.status.newVal)
  result = i.dset(result, "headers".newVal, i.newVal(resp.headers))
  result = i.dset(result, "body".newVal, resp.body.newVal)

# Http

proc http_module*(i: In)=
  let def = i.define()

  def.symbol("request") do (i: In):
    let vals = i.expect "dict"
    let req = vals[0]
    i.push i.execRequest(req)
  
  def.symbol("get-content") do (i: In):
    let vals = i.expect "string"
    let url = vals[0]
    let cli = newCli()
    i.push cli.getContent(url.getString).newVal

  def.symbol("post-content") do (i: In):
    discard

  def.symbol("download") do (i: In):
    let vals = i.expect("string", "string")
    let file = vals[0]
    let url = vals[1]
    let cli = newCli()
    cli.downloadFile(url.getString, file.getString)
    discard

  def.symbol("put-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "PUT".newVal)
    i.push i.execRequest(req)
  
  def.symbol("get-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "GET".newVal)
    i.push i.execRequest(req)
  
  def.symbol("post-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "POST".newVal)
    i.push i.execRequest(req)
  
  def.symbol("head-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "HEAD".newVal)
    i.push i.execRequest(req)

  def.symbol("options-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "OPTIONS".newVal)
    i.push i.execRequest(req)
  
  def.symbol("patch-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "PATCH".newVal)
    i.push i.execRequest(req)

  def.symbol("delete-request") do (i: In):
    let vals = i.expect "dict"
    var req = vals[0]
    req = i.dset(req, "method".newVal, "DELETE".newVal)
    i.push i.execRequest(req)

  def.finalize("http")
