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
  i.define()

    .symbol("md5") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.getMD5.newVal

    .symbol("sha1") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push compute(s.getString).toHex.newVal

    .symbol("sha224") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push computeSHA224(s.getString).hex.toLowerAscii.newVal

    .symbol("sha256") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push computeSHA256(s.getString).hex.toLowerAscii.newVal

    .symbol("sha384") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push computeSHA384(s.getString).hex.toLowerAscii.newVal

    .symbol("sha512") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push computeSHA512(s.getString).hex.toLowerAscii.newVal

    .symbol("encode") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.encode.newVal
      
    .symbol("decode") do (i: In):
      var s: MinValue
      i.reqStringLike s
      i.push s.getString.decode.newVal

    .symbol("aes") do (i: In):
      var s, k: MinValue
      i.reqTwoStrings k, s
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

    .finalize("crypto")
