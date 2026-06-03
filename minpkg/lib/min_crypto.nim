import
  std/[base64,
  strutils,
  times]
import
  ../core/parser,
  ../core/value,
  ../core/interpreter,
  ../core/utils
when defined(static):
  import os

when defined(ssl) and defined(static):   
  import
    openssl


  when defined(amd64):

    when defined(windows):
      {.passL: "-static -L"&currentSourcePath().parentDir.parentDir&"/vendor/openssl/windows/x64 -lssl -lcrypto -lgdi32 -ladvapi32 -luser32 -lws2_32 -lcrypt32".}
    elif defined(linux):
      {.passL: "-static -L"&currentSourcePath().parentDir.parentDir&"/vendor/openssl/linux/x64 -lssl -lcrypto".}
    elif defined(macosx):
      {.passL: "-Bstatic -L"&currentSourcePath().parentDir.parentDir&"/vendor/openssl/macosx/x64 -lssl -lcrypto -Bdynamic".}
    else:
      {.passL: "-Bstatic -L"&currentSourcePath().parentDir.parentDir&"/vendor/openssl/unknown -lssl -lcrypto -Bdynamic".}
  else:
    {.passL: "-Bstatic -L"&currentSourcePath().parentDir.parentDir&"/vendor/openssl/unknown -lssl -lcrypto -Bdynamic".}
      

  proc MD4(d: cstring, n: culong, md: cstring = nil): cstring {.cdecl, importc.}
  proc EVP_MD_CTX_new*(): EVP_MD_CTX {.cdecl, importc: "EVP_MD_CTX_new".}
  proc EVP_MD_CTX_free*(ctx: EVP_MD_CTX) {.cdecl, importc: "EVP_MD_CTX_free".}
  type EVP_CIPHER_CTX = SslPtr
  type EVP_CIPHER = SslPtr
  proc EVP_CIPHER_CTX_new(): EVP_CIPHER_CTX {.cdecl, importc: "EVP_CIPHER_CTX_new".}
  proc EVP_CIPHER_CTX_free(ctx: EVP_CIPHER_CTX) {.cdecl, importc: "EVP_CIPHER_CTX_free".}
  proc EVP_aes_256_ctr(): EVP_CIPHER {.cdecl, importc: "EVP_aes_256_ctr".}
  proc EVP_EncryptInit_ex(ctx: EVP_CIPHER_CTX, cipher: EVP_CIPHER, engine: SslPtr,
      key: ptr uint8, iv: ptr uint8): cint {.cdecl, importc: "EVP_EncryptInit_ex".}
  proc EVP_EncryptUpdate(ctx: EVP_CIPHER_CTX, outBuf: ptr uint8, outLen: ptr cint,
      inBuf: ptr uint8, inLen: cint): cint {.cdecl, importc: "EVP_EncryptUpdate".}
  proc EVP_EncryptFinal_ex(ctx: EVP_CIPHER_CTX, outBuf: ptr uint8,
      outLen: ptr cint): cint {.cdecl, importc: "EVP_EncryptFinal_ex".}
else:
  import
    checksums/sha1,
    checksums/md5

proc crypto_module*(i: In) =
  let def = i.define()


  def.symbol("encode") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.encode.newVal

  def.symbol("decode") do (i: In):
    let vals = i.expect("'sym")
    let s = vals[0]
    i.push s.getString.decode.newVal

  when defined(ssl) and defined(static):

    proc hash(s: string, kind: EVP_MD, size: Natural): string =
      var hash = alloc(size)
      let ctx = EVP_MD_CTX_new()
      discard EVP_DigestInit_ex(ctx, kind, nil)
      discard EVP_DigestUpdate(ctx, s.cstring, s.len.cuint)
      discard EVP_DigestFinal_ex(ctx, hash, nil)
      EVP_MD_CTX_free(ctx)
      var hashStr = newString(size)
      copyMem(addr(hashStr[0]), hash, size)
      dealloc(hash)
      return hashStr.toHex.toLowerAscii[0..size-1]

    def.symbol("md5") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push hash(s, EVP_md5(), 32).newVal

    def.symbol("md4") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      var result = ""
      var str = MD4(s.cstring, s.len.culong)
      for i in 0 ..< 16:
        result.add str[i].BiggestInt.toHex(2).toLower
      i.push result.newVal

    def.symbol("sha1") do (i: In):
      let vals = i.expect("'sym")
      var s = vals[0].getString
      i.push hash(s, EVP_sha1(), 40).newVal

    def.symbol("sha224") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push hash(s, EVP_sha224(), 56).newVal

    def.symbol("sha256") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push hash(s, EVP_sha256(), 64).newVal

    def.symbol("sha384") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push hash(s, EVP_sha384(), 96).newVal

    def.symbol("sha512") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push hash(s, EVP_sha512(), 128).newVal

    def.symbol("aes") do (i: In):
      let vals = i.expect("'sym", "'sym")
      let k = vals[0]
      let s = vals[1]
      var text = s.getString
      var key = hash(k.getString, EVP_sha256(), 64)
      var iv = hash((key & $getTime().toUnix), EVP_sha256(), 64)
      # AES-256-CTR requires 32-byte key and 16-byte IV
      var keyBytes = newSeq[uint8](32)
      for j in 0 ..< 32:
        keyBytes[j] = cast[uint8](key[j])
      var ivBytes = newSeq[uint8](16)
      for j in 0 ..< 16:
        ivBytes[j] = cast[uint8](iv[j])
      let ctx = EVP_CIPHER_CTX_new()
      if ctx.isNil:
        raiseInvalid("Failed to create cipher context")
      try:
        if EVP_EncryptInit_ex(ctx, EVP_aes_256_ctr(), nil,
            addr keyBytes[0], addr ivBytes[0]) != 1:
          raiseInvalid("Failed to initialize AES-256-CTR")
        var outBuf = newSeq[uint8](text.len + 16)
        var outLen: cint = 0
        var totalLen: cint = 0
        if text.len > 0:
          if EVP_EncryptUpdate(ctx, addr outBuf[0], addr outLen,
              cast[ptr uint8](addr text[0]), text.len.cint) != 1:
            raiseInvalid("Failed to encrypt data")
          totalLen = outLen
        var finalLen: cint = 0
        if EVP_EncryptFinal_ex(ctx, addr outBuf[totalLen], addr finalLen) != 1:
          raiseInvalid("Failed to finalize encryption")
        totalLen += finalLen
        var result = newString(totalLen)
        if totalLen > 0:
          copyMem(addr result[0], addr outBuf[0], totalLen)
        i.push result.newVal
      finally:
        EVP_CIPHER_CTX_free(ctx)

  else:

    def.symbol("md5") do (i: In):
      let vals = i.expect("'sym")
      let s = vals[0].getString
      i.push newVal($toMD5(s))

    def.symbol("sha1") do (i: In):
      let vals = i.expect("'sym")
      var s = vals[0].getString
      i.push newVal(toLowerAscii($secureHash(s)))

  def.finalize("crypto")
