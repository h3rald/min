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
  ../packages/nimAES/nimAES

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
    var ctx: AESContext
    var text = s.getString
    var length = text.len
    if length div 16 == 0:
      text &= " ".repeat(16 - length)
    elif length mod 16 != 0 and length div 16 >= 1:
      text &= " ".repeat((length div 16 + 1) * 16 - length)
    var key = k.getString.compute.toHex # SHA1 of key, to make sure it's long enough
    var nonce = key[0..15]
    i.push ctx.cryptOFB(nonce, text).newVal

  def.finalize("crypto")
