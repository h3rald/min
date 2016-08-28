# AES, Rijndael Algorithm implementation written in nim
#
# Copyright (c) 2015 Andri Lim
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#
#-------------------------------------

import strutils

type
  AESTable = object
    FSb, RSb: array[0..255, uint8]
    FT0, FT1, FT2, FT3, RT0, RT1, RT2, RT3: array[0..255, uint32]
    RCON: array[0..9, uint32]

  AESContext* = object
    nr: int
    rk: int
    buf: array[0..67, uint32]

proc initAES*(): AESContext =
  result.nr = 0
  result.rk = 0
  for i in 0..result.buf.len-1: result.buf[i] = 0
  
proc ROTL8(x: uint32): uint32 =
  result = (x shl 8) or (x shr 24)

proc XTIME[T](x: T): T =
  result = x shl T(1)
  if (x and T(0x80)) != T(0): result = result xor T(0x1B)
  else: result = result xor T(0x00)

proc computeRoundConstant(): array[0..9, uint32] =
  var x = 1'u32
  for i in 0..9:
    result[i] = x
    x = XTIME(x) and 0xFF

#compute pow and log tables over GF(2xor8)
proc computePowLog(): tuple[pow: array[0..255, int], log: array[0..255, int]] =
  var x = 1
  for i in 0..255:
    result.pow[i] = x
    result.log[x] = i
    x = (x xor XTIME(x)) and 0xFF

proc MUL(x, y: uint8, pow, log: array[0..255, int]): uint32 =
  result = 0
  if x != 0 and y != 0: result = uint32(pow[((log[x]+log[y]) mod 255)])

proc computeTable*(): AESTable =
  let (pow, log) = computePowLog()
  result.RCON = computeRoundConstant()

  template srl(x, y: typed, s: untyped): untyped =
    y = ((y shl 1) or (y shr 7)) and 0xFF
    s

  result.FSb[0] = 0x63
  result.RSb[0x63] = 0
  for i in 1..255:
    var x = pow[255 - log[i]]
    var y = x
    srl(x, y): x = x xor y
    srl(x, y): x = x xor y
    srl(x, y): x = x xor y
    srl(x, y): x = x xor y xor 0x63
    result.FSb[i] = uint8(x)
    result.RSb[x] = uint8(i)

  # generate the forward and reverse tables
  for i in 0..255:
    let x = result.FSb[i]
    let y = XTIME(x) and 0xFF
    let z = (y xor x) and 0xFF

    result.FT0[i] = uint32(y) xor (uint32(x) shl 8) xor
      (uint32(x) shl 16) xor (uint32(z) shl 24)

    result.FT1[i] = ROTL8(result.FT0[i])
    result.FT2[i] = ROTL8(result.FT1[i])
    result.FT3[i] = ROTL8(result.FT2[i])

    let w = result.RSb[i]
    result.RT0[i] = MUL(0x0E, w, pow, log) xor (MUL(0x09, w, pow, log) shl 8) xor
      (MUL(0x0D, w, pow, log) shl 16) xor (MUL(0x0B, w, pow, log) shl 24)

    result.RT1[i] = ROTL8(result.RT0[i])
    result.RT2[i] = ROTL8(result.RT1[i])
    result.RT3[i] = ROTL8(result.RT2[i])

proc version(major, minor, patch: int): int {.compiletime.} =
  result = major+minor+patch

const compilerVersion = version(NimMajor,NimMinor,NimPatch)

when compilerVersion <= version(0,11,2):
  let SBOX = computeTable()
elif compilerVersion >= version(0,11,3):
  const SBOX = computeTable()

proc GET_ULONG_LE(b: cstring, i: int): uint32 =
  result = cast[uint32](ord(b[i]) or (ord(b[i+1]) shl 8) or (ord(b[i+2]) shl 16) or (ord(b[i+3]) shl 24))

proc PUT_ULONG_LE(n: uint32, b: var cstring, i: int) =
  b[i]   = chr(int(n and 0xFF))
  b[i+1] = chr(int((n shr 8) and 0xFF))
  b[i+2] = chr(int((n shr 16) and 0xFF))
  b[i+3] = chr(int((n shr 24) and 0xFF))

proc setEncodeKey*(ctx: var AESContext, key: string): bool =
  var keySize = key.len * 8
  zeroMem(addr(ctx), sizeof(ctx))

  case keySize:
  of 128: ctx.nr = 10
  of 192: ctx.nr = 12
  of 256: ctx.nr = 14
  else: return false

  let len = keySize div 32
  for i in 0..len-1: ctx.buf[i] = GET_ULONG_LE(cstring(key), i * 4)

  var RK = 0
  if ctx.nr == 10:
    for i in 0..9:
      ctx.buf[RK+4] = ctx.buf[RK+0] xor SBOX.RCON[i] xor
        uint32(SBOX.FSb[(int(ctx.buf[RK+3] shr 8) and 0xFF)]) xor
        (uint32(SBOX.FSb[(int(ctx.buf[RK+3] shr 16) and 0xFF)]) shl 8) xor
        (uint32(SBOX.FSb[(int(ctx.buf[RK+3] shr 24) and 0xFF)]) shl 16) xor
        (uint32(SBOX.FSb[(int(ctx.buf[RK+3]) and 0xFF)]) shl 24)

      ctx.buf[RK+5] = ctx.buf[RK+1] xor ctx.buf[RK+4]
      ctx.buf[RK+6] = ctx.buf[RK+2] xor ctx.buf[RK+5]
      ctx.buf[RK+7] = ctx.buf[RK+3] xor ctx.buf[RK+6]
      inc(RK, 4)

  elif ctx.nr == 12:
    for i in 0..7:
      ctx.buf[RK+6] = ctx.buf[RK+0] xor SBOX.RCON[i] xor
        uint32(SBOX.FSb[int(ctx.buf[RK+5] shr 8) and 0xFF]) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+5] shr 16) and 0xFF]) shl 8) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+5] shr 24) and 0xFF]) shl 16) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+5]) and 0xFF]) shl 24)

      ctx.buf[RK+7] = ctx.buf[RK+1] xor ctx.buf[RK+6]
      ctx.buf[RK+8] = ctx.buf[RK+2] xor ctx.buf[RK+7]
      ctx.buf[RK+9] = ctx.buf[RK+3] xor ctx.buf[RK+8]
      ctx.buf[RK+10] = ctx.buf[RK+4] xor ctx.buf[RK+9]
      ctx.buf[RK+11] = ctx.buf[RK+5] xor ctx.buf[RK+10]
      inc(RK, 6)

  elif ctx.nr == 14:
    for i in 0..6:
      ctx.buf[RK+8] = ctx.buf[RK+0] xor SBOX.RCON[i] xor
        uint32(SBOX.FSb[int(ctx.buf[RK+7] shr 8) and 0xFF]) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+7] shr 16) and 0xFF]) shl 8) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+7] shr 24) and 0xFF]) shl 16) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+7]) and 0xFF]) shl 24)

      ctx.buf[RK+9] = ctx.buf[RK+1] xor ctx.buf[RK+8]
      ctx.buf[RK+10] = ctx.buf[RK+2] xor ctx.buf[RK+9]
      ctx.buf[RK+11] = ctx.buf[RK+3] xor ctx.buf[RK+10]

      ctx.buf[RK+12] = ctx.buf[RK+4] xor
        uint32(SBOX.FSb[int(ctx.buf[RK+11]) and 0xFF]) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+11] shr 8) and 0xFF]) shl 8) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+11] shr 16) and 0xFF]) shl 16) xor
        (uint32(SBOX.FSb[int(ctx.buf[RK+11] shr 24) and 0xFF]) shl 24)

      ctx.buf[RK+13] = ctx.buf[RK+5] xor ctx.buf[RK+12]
      ctx.buf[RK+14] = ctx.buf[RK+6] xor ctx.buf[RK+13]
      ctx.buf[RK+15] = ctx.buf[RK+7] xor ctx.buf[RK+14]
      inc(RK, 8)

  result = true

proc setDecodeKey*(ctx: var AESContext, key: string): bool =
  var keySize = key.len * 8
  zeroMem(addr(ctx), sizeof(ctx))

  case keySize:
  of 128: ctx.nr = 10
  of 192: ctx.nr = 12
  of 256: ctx.nr = 14
  else: return false
  var cty: AESContext
  if not cty.setEncodeKey(key): return false
  var SK = cty.nr * 4
  var RK = 0

  ctx.buf[RK] = cty.buf[SK]
  ctx.buf[RK+1] = cty.buf[SK+1]
  ctx.buf[RK+2] = cty.buf[SK+2]
  ctx.buf[RK+3] = cty.buf[SK+3]
  inc(RK, 4)
  dec(SK, 4)

  for i in countdown(ctx.nr-1, 1):
    for j in 0..3:
      let YSK = cty.buf[SK]
      ctx.buf[RK] = SBOX.RT0[SBOX.FSb[int(YSK) and 0xFF]] xor
        SBOX.RT1[SBOX.FSb[int(YSK shr 8) and 0xFF]] xor
        SBOX.RT2[SBOX.FSb[int(YSK shr 16) and 0xFF]] xor
        SBOX.RT3[SBOX.FSb[int(YSK shr 24) and 0xFF]]
      inc SK
      inc RK
    dec(SK, 8)

  ctx.buf[RK] = cty.buf[SK]
  ctx.buf[RK+1] = cty.buf[SK+1]
  ctx.buf[RK+2] = cty.buf[SK+2]
  ctx.buf[RK+3] = cty.buf[SK+3]
  result = true

template AES_FROUND(X0,X1,X2,X3,Y0,Y1,Y2,Y3: typed): untyped =
  X0 = ctx.buf[RK] xor SBOX.FT0[int(Y0 and 0xFF)] xor
    SBOX.FT1[int((Y1 shr 8) and 0xFF)] xor
    SBOX.FT2[int((Y2 shr 16) and 0xFF)] xor
    SBOX.FT3[int((Y3 shr 24) and 0xFF)]
  inc RK

  X1 = ctx.buf[RK] xor SBOX.FT0[int(Y1 and 0xFF)] xor
    SBOX.FT1[int((Y2 shr 8) and 0xFF)] xor
    SBOX.FT2[int((Y3 shr 16) and 0xFF)] xor
    SBOX.FT3[int((Y0 shr 24) and 0xFF)]
  inc RK

  X2 = ctx.buf[RK] xor SBOX.FT0[int(Y2 and 0xFF)] xor
    SBOX.FT1[int((Y3 shr 8) and 0xFF)] xor
    SBOX.FT2[int((Y0 shr 16) and 0xFF)] xor
    SBOX.FT3[int((Y1 shr 24) and 0xFF)]
  inc RK

  X3 = ctx.buf[RK] xor SBOX.FT0[int(Y3 and 0xFF)] xor
    SBOX.FT1[int((Y0 shr 8) and 0xFF)] xor
    SBOX.FT2[int((Y1 shr 16) and 0xFF)] xor
    SBOX.FT3[int((Y2 shr 24) and 0xFF)]
  inc RK

template AES_RROUND(X0,X1,X2,X3,Y0,Y1,Y2,Y3: typed): untyped =
  X0 = ctx.buf[RK] xor SBOX.RT0[int(Y0 and 0xFF)] xor
    SBOX.RT1[int((Y3 shr 8) and 0xFF)] xor
    SBOX.RT2[int((Y2 shr 16) and 0xFF)] xor
    SBOX.RT3[int((Y1 shr 24) and 0xFF)]
  inc RK

  X1 = ctx.buf[RK] xor SBOX.RT0[int(Y1 and 0xFF)] xor
    SBOX.RT1[int((Y0 shr 8) and 0xFF)] xor
    SBOX.RT2[int((Y3 shr 16) and 0xFF)] xor
    SBOX.RT3[int((Y2 shr 24) and 0xFF)]
  inc RK

  X2 = ctx.buf[RK] xor SBOX.RT0[int(Y2  and 0xFF)] xor
    SBOX.RT1[int((Y1 shr 8) and 0xFF)] xor
    SBOX.RT2[int((Y0 shr 16) and 0xFF)] xor
    SBOX.RT3[int((Y3 shr 24) and 0xFF)]
  inc RK

  X3 = ctx.buf[RK] xor SBOX.RT0[int(Y3 and 0xFF)] xor
    SBOX.RT1[int((Y2 shr 8) and 0xFF)] xor
    SBOX.RT2[int((Y1 shr 16) and 0xFF)] xor
    SBOX.RT3[int((Y0 shr 24) and 0xFF)]
  inc RK

proc encryptECB*(ctx: AESContext, input: cstring, output: var cstring) =
  var X0, X1, X2, X3, Y0, Y1, Y2, Y3: uint32
  var RK = 0

  X0 = GET_ULONG_LE(input, 0)
  X1 = GET_ULONG_LE(input, 4)
  X2 = GET_ULONG_LE(input, 8)
  X3 = GET_ULONG_LE(input, 12)

  X0 = X0 xor ctx.buf[RK]
  X1 = X1 xor ctx.buf[RK+1]
  X2 = X2 xor ctx.buf[RK+2]
  X3 = X3 xor ctx.buf[RK+3]
  inc(RK, 4)

  for i in countdown((ctx.nr shr 1) - 1, 1):
    AES_FROUND(Y0, Y1, Y2, Y3, X0, X1, X2, X3)
    AES_FROUND(X0, X1, X2, X3, Y0, Y1, Y2, Y3)

  AES_FROUND(Y0, Y1, Y2, Y3, X0, X1, X2, X3)

  X0 = ctx.buf[RK] xor uint32(SBOX.FSb[int(Y0 and 0xFF)]) xor
    (uint32(SBOX.FSb[int((Y1 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.FSb[int((Y2 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.FSb[int((Y3 shr 24) and 0xFF)]) shl 24)
  inc RK

  X1 = ctx.buf[RK] xor uint32(SBOX.FSb[int(Y1 and 0xFF)]) xor
    (uint32(SBOX.FSb[int((Y2 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.FSb[int((Y3 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.FSb[int((Y0 shr 24) and 0xFF)]) shl 24)
  inc RK

  X2 = ctx.buf[RK] xor uint32(SBOX.FSb[int(Y2 and 0xFF)]) xor
    (uint32(SBOX.FSb[int((Y3 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.FSb[int((Y0 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.FSb[int((Y1 shr 24) and 0xFF)]) shl 24)
  inc RK

  X3 = ctx.buf[RK] xor uint32(SBOX.FSb[int(Y3 and 0xFF)]) xor
    (uint32(SBOX.FSb[int((Y0 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.FSb[int((Y1 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.FSb[int((Y2 shr 24) and 0xFF)]) shl 24)

  PUT_ULONG_LE(X0, output, 0)
  PUT_ULONG_LE(X1, output, 4)
  PUT_ULONG_LE(X2, output, 8)
  PUT_ULONG_LE(X3, output, 12)

proc encryptECB*(ctx: AESContext, input: string): string =
  assert input.len == 16
  result = newString(16)
  var output = cstring(result)
  ctx.encryptECB(cstring(input), output)

proc decryptECB*(ctx: AESContext, input: cstring, output: var cstring) =
  var X0, X1, X2, X3, Y0, Y1, Y2, Y3: uint32
  var RK = 0

  X0 = GET_ULONG_LE(input, 0)
  X1 = GET_ULONG_LE(input, 4)
  X2 = GET_ULONG_LE(input, 8)
  X3 = GET_ULONG_LE(input, 12)

  X0 = X0 xor ctx.buf[RK]
  X1 = X1 xor ctx.buf[RK+1]
  X2 = X2 xor ctx.buf[RK+2]
  X3 = X3 xor ctx.buf[RK+3]
  inc(RK, 4)

  for i in countdown((ctx.nr shr 1) - 1, 1):
    AES_RROUND(Y0, Y1, Y2, Y3, X0, X1, X2, X3)
    AES_RROUND(X0, X1, X2, X3, Y0, Y1, Y2, Y3)

  AES_RROUND(Y0, Y1, Y2, Y3, X0, X1, X2, X3)

  X0 = ctx.buf[RK] xor uint32(SBOX.RSb[int(Y0 and 0xFF)]) xor
    (uint32(SBOX.RSb[int((Y3 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.RSb[int((Y2 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.RSb[int((Y1 shr 24) and 0xFF)]) shl 24)
  inc RK

  X1 = ctx.buf[RK] xor uint32(SBOX.RSb[int(Y1 and 0xFF)]) xor
    (uint32(SBOX.RSb[int((Y0 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.RSb[int((Y3 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.RSb[int((Y2 shr 24) and 0xFF)]) shl 24)
  inc RK

  X2 = ctx.buf[RK] xor uint32(SBOX.RSb[int(Y2 and 0xFF)]) xor
    (uint32(SBOX.RSb[int((Y1 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.RSb[int((Y0 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.RSb[int((Y3 shr 24) and 0xFF)]) shl 24)
  inc RK

  X3 = ctx.buf[RK] xor uint32(SBOX.RSb[int(Y3 and 0xFF)]) xor
    (uint32(SBOX.RSb[int((Y2 shr 8) and 0xFF)]) shl 8) xor
    (uint32(SBOX.RSb[int((Y1 shr 16) and 0xFF)]) shl 16) xor
    (uint32(SBOX.RSb[int((Y0 shr 24) and 0xFF)]) shl 24)

  PUT_ULONG_LE(X0, output, 0)
  PUT_ULONG_LE(X1, output, 4)
  PUT_ULONG_LE(X2, output, 8)
  PUT_ULONG_LE(X3, output, 12)

proc decryptECB*(ctx: AESContext, input: string): string =
  assert input.len == 16
  result = newString(16)
  var output = cstring(result)
  ctx.decryptECB(cstring(input), output)
  
proc cryptOFB*(ctx: AESContext, nonce: var cstring, input: string): string =
  var len = input.len
  if (len mod 16) != 0: return nil

  result = newString(len)
  var x = 0
  while len > 0:
    var output = cast[cstring](addr(result[x]))
    encryptECB(ctx, nonce, output)
    copyMem(addr(nonce[0]), output, 16)

    for i in 0..15:
      output[i] = chr(ord(output[i]) xor ord(input[x+i]))

    inc(x, 16)
    dec(len, 16)

proc cryptOFB*(ctx: AESContext, nonce: var string, input: string): string =
  assert(nonce.len == 16)
  assert((input.len mod 16) == 0)
  var counter = cstring(nonce)
  result = ctx.cryptOFB(counter, input)

proc encryptCBC*(ctx: AESContext, iv: cstring, input: string): string =
  var len = input.len
  if (len mod 16) != 0: return nil

  result = newString(len)
  var x = 0
  while len > 0:
    var output = cast[cstring](addr(result[x]))

    for i in 0..15:
      output[i] = chr(ord(input[x+i]) xor ord(iv[i]))

    encryptECB(ctx, output, output)
    copyMem(iv, output, 16)

    inc(x, 16)
    dec(len, 16)

proc encryptCBC*(ctx: AESContext, iv: string, input: string): string =
  assert iv.len == 16
  result = ctx.encryptCBC(cstring(iv), input)

proc decryptCBC*(ctx: AESContext, iv: cstring, inp: string): string =
  var len = inp.len
  if (len mod 16) != 0: return nil

  var data = cstring(inp)
  result = newString(len)
  var x = 0
  var temp: array[0..15, char]
  while len > 0:
    var input = cast[cstring](addr(data[x]))
    var output = cast[cstring](addr(result[x]))
    copyMem(addr(temp[0]), input, 16)
    ctx.decryptECB(input, output)

    for i in 0..15:
      output[i] = chr(ord(output[i]) xor ord(iv[i]))

    copyMem(iv, addr(temp[0]), 16)

    inc(x, 16)
    dec(len, 16)

proc decryptCBC*(ctx: AESContext, iv: string, input: string): string =
  assert iv.len == 16
  result = ctx.decryptCBC(cstring(iv), input)
  
proc encryptCFB128*(ctx: AESContext, iv_off: var int, iv: var cstring, input: string): string =
  var n = iv_off
  var len = input.len
  var i = 0
  result = newString(len)

  while len > 0:
    if n == 0: encryptECB(ctx, iv, iv)
    iv[n] = chr( ord(iv[n]) xor ord(input[i]) )
    result[i] = iv[n]

    n = ( n + 1 ) and 0x0F
    dec len
    inc i

  iv_off = n

proc encryptCFB128*(ctx: AESContext, iv_off: var int, iv: var string, input: string): string =
  assert iv.len == 16
  var initVector = cstring(iv)
  result = ctx.encryptCFB128(iv_off, initVector, input)

proc decryptCFB128*(ctx: AESContext, iv_off: var int, iv: var cstring, input: string): string =
  var n = iv_off
  var len = input.len
  var i = 0
  result = newString(len)

  while len > 0:
    if n == 0: encryptECB(ctx, iv, iv)
    result[i] = chr(ord(input[i]) xor ord(iv[n]))
    iv[n] = input[i]

    n = ( n + 1 ) and 0x0F
    dec len
    inc i

  iv_off = n

proc decryptCFB128*(ctx: AESContext, iv_off: var int, iv: var string, input: string): string =
  assert iv.len == 16
  var initVector = cstring(iv)
  result = ctx.decryptCFB128(iv_off, initVector, input)

proc encryptCFB8*(ctx: AESContext, iv: var cstring, input: string): string =
  var len = input.len
  var i = 0
  result = newString(len)
  var ov: array[0..16, char]

  while len > 0:
    copyMem(addr(ov), iv, 16)
    encryptECB(ctx, iv, iv)
    result[i] = chr(ord(iv[0]) xor ord(input[i]))
    ov[16] = result[i]
    copyMem(iv, addr(ov[1]), 16)
    inc i
    dec len

proc encryptCFB8*(ctx: AESContext, iv: var string, input: string): string =
  assert iv.len == 16
  var initVector = cstring(iv)
  result = ctx.encryptCFB8(initVector, input)

proc decryptCFB8*(ctx: AESContext, iv: var cstring, input: string): string =
  var len = input.len
  var i = 0
  result = newString(len)
  var ov: array[0..16, char]

  while len > 0:
    copyMem(addr(ov), iv, 16)
    encryptECB(ctx, iv, iv)
    ov[16] = input[i]
    result[i] = chr(ord(iv[0]) xor ord(input[i]))
    copyMem(iv, addr(ov[1]), 16)
    inc i
    dec len

proc decryptCFB8*(ctx: AESContext, iv: var string, input: string): string =
  assert iv.len == 16
  var initVector = cstring(iv)
  result = ctx.decryptCFB8(initVector, input)

proc cryptCTR*(ctx: AESContext, nc_off: var int, nonce: var cstring, input: string): string =
  var n = nc_off
  var x = 0
  var len = input.len
  var counter = cast[ptr array[0..15, uint8]](nonce)

  var temp: array[0..15, uint8]
  var stream_block = cast[cstring](addr(temp[0]))
  result = newString(len)

  while len > 0:
    if n == 0:
      encryptECB(ctx, nonce, stream_block)
      for i in countdown(16, 1):
        counter[][i-1] += 1
        if counter[][i-1] != 0: break

    result[x] = chr(ord(input[x]) xor ord(stream_block[n]))

    n = ( n + 1 ) and 0x0F
    dec len
    inc x

  nc_off = n

proc cryptCTR*(ctx: AESContext, nc_off: var int, nonce: var string, input: string): string =
  assert nonce.len == 16
  var initVector = cstring(nonce)
  result = ctx.cryptCTR(nc_off, initVector, input)
