import
  md5,
  base64,
  strutils,
  times
import
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils
import
  ../packages/sha1/sha1,
  ../packages/nimSHA2/nimSHA2,
  ../vendor/aes/aes

{.compile: "../vendor/aes/libaes.c".}

proc crypto_module*(i: In)=
  let def = i.define()

  def.symbol("md5") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.getMD5.newVal

  def.symbol("sha1") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push compute(s.getString).toHex.newVal

  def.symbol("sha224") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push computeSHA224(s.getString).hex.toLowerAscii.newVal

  def.symbol("sha256") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push computeSHA256(s.getString).hex.toLowerAscii.newVal

  def.symbol("sha384") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push computeSHA384(s.getString).hex.toLowerAscii.newVal

  def.symbol("sha512") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push computeSHA512(s.getString).hex.toLowerAscii.newVal

  def.symbol("encode") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.encode.newVal
    
  def.symbol("decode") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.decode.newVal

  def.symbol("aes") do (i: In):
    let vals = i.expect("'sym", "'sym")
    let k = vals[0]
    let s = vals[1]
    var text = s.getString
    var key = k.getString.compute.toHex
    var iv = (key & $getTime().toUnix).compute.toHex
    var ctx = cast[ptr AES_ctx](alloc0(sizeof(AES_ctx)))
    AES_init_ctx_iv(ctx, cast[ptr uint8](key[0].addr), cast[ptr uint8](iv[0].addr));
    var input = cast[ptr uint8](text[0].addr)
    AES_CTR_xcrypt_buffer(ctx, input, text.len.uint32);
    i.push text.newVal

  def.finalize("crypto")
