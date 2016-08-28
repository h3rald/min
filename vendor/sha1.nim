#Copyright (c) 2011, Micael Hildenborg
#All rights reserved.

#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#* Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#* Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#* Neither the name of Micael Hildenborg nor the
#  names of its contributors may be used to endorse or promote products
#  derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY Micael Hildenborg ''AS IS'' AND ANY
#EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL Micael Hildenborg BE LIABLE FOR ANY
#DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#Ported to Nimrod by Erik O'Leary
#

## Imports
import unsigned, strutils, base64

## Fields
const sha_digest_size = 20

## Types
type
  SHA1State   = array[0 .. 5-1, uint32]
  SHA1Buffer  = array[0 .. 80-1, uint32]
  SHA1Digest* = array[0 .. sha_digest_size-1, uint8]

## Templates & Procedures
template clearBuffer(w: SHA1Buffer, len = 16) =
  zeroMem(addr(w), len * sizeof(uint32))

proc toHex*(digest: SHA1Digest): string =
  const digits = "0123456789abcdef"

  var arr: array[0 .. sha_digest_size*2, char]

  for hashByte in countdown(20-1, 0):
    arr[hashByte shl 1] = digits[(digest[hashByte] shr 4) and 0xf]
    arr[(hashByte shl 1) + 1] = digits[(digest[hashByte]) and 0xf]

  return $arr

proc toBase64*(digest: SHA1Digest): string = base64.encode(digest)

proc init(result: var SHA1State) =
  result[0] = 0x67452301'u32
  result[1] = 0xefcdab89'u32
  result[2] = 0x98badcfe'u32
  result[3] = 0x10325476'u32
  result[4] = 0xc3d2e1f0'u32

proc innerHash(state: var SHA1State, w: var SHA1Buffer) =
  var
    a = state[0]
    b = state[1]
    c = state[2]
    d = state[3]
    e = state[4]

  var round = 0

  template rot(value, bits: uint32): uint32 {.immediate.} =
    (value shl bits) or (value shr (32 - bits))

  template sha1(fun, val: uint32): stmt =
    let t = rot(a, 5) + fun + e + val + w[round]
    e = d
    d = c
    c = rot(b, 30)
    b = a
    a = t

  template process(body: stmt): stmt =
    w[round] = rot(w[round - 3] xor w[round - 8] xor w[round - 14] xor w[round - 16], 1)
    body
    inc(round)

  template wrap(dest, value: expr): stmt {.immediate.} =
    let v = dest + value
    dest = v

  while round < 16:
    sha1((b and c) or (not b and d), 0x5a827999'u32)
    inc(round)

  while round < 20:
    process:
      sha1((b and c) or (not b and d), 0x5a827999'u32)

  while round < 40:
    process:
      sha1(b xor c xor d, 0x6ed9eba1'u32)

  while round < 60:
    process:
      sha1((b and c) or (b and d) or (c and d), 0x8f1bbcdc'u32)

  while round < 80:
    process:
      sha1(b xor c xor d, 0xca62c1d6'u32)

  wrap state[0], a
  wrap state[1], b
  wrap state[2], c
  wrap state[3], d
  wrap state[4], e

template computeInternal(src: expr): stmt {.immediate.} =
  #Initialize state
  var state: SHA1State
  init(state)

  #Create w buffer
  var w: SHA1Buffer

  #Loop through all complete 64byte blocks.
  let byteLen         = src.len
  let endOfFullBlocks = byteLen - 64
  var endCurrentBlock = 0
  var currentBlock    = 0

  while currentBlock <= endOfFullBlocks:
    endCurrentBlock = currentBlock + 64

    var i = 0
    while currentBlock < endCurrentBlock:
      w[i] = uint32(src[currentBlock+3]) or
             uint32(src[currentBlock+2]) shl 8'u32 or
             uint32(src[currentBlock+1]) shl 16'u32 or
             uint32(src[currentBlock])   shl 24'u32
      currentBlock += 4
      inc(i)

    innerHash(state, w)

  #Handle last and not full 64 byte block if existing
  endCurrentBlock = byteLen - currentBlock
  clearBuffer(w)
  var lastBlockBytes = 0

  while lastBlockBytes < endCurrentBlock:

    var value = uint32(src[lastBlockBytes + currentBlock]) shl
                ((3'u32 - (lastBlockBytes and 3)) shl 3)

    w[lastBlockBytes shr 2] = w[lastBlockBytes shr 2] or value
    inc(lastBlockBytes)

  w[lastBlockBytes shr 2] = w[lastBlockBytes shr 2] or (
    0x80'u32 shl ((3'u32 - (lastBlockBytes and 3)) shl 3)
  )

  if endCurrentBlock >= 56:
    innerHash(state, w)
    clearBuffer(w)

  w[15] = uint32(byteLen) shl 3
  innerHash(state, w)

  # Store hash in result pointer, and make sure we get in in the correct order on both endian models.
  for i in 0 .. sha_digest_size-1:
    result[i] = uint8((int(state[i shr 2]) shr ((3-(i and 3)) * 8)) and 255)

proc compute*(src: string) : SHA1Digest =
  ## Calculate SHA1 from input string
  computeInternal(src)

proc compute*(src: openarray[TInteger|char]) : SHA1Digest =
  ## Calculate SHA1 from input array
  computeInternal(src)

when isMainModule:
  var result: string

  #test sha1 - char array input
  result = compute(@['s','h','o','r','t','e','r']).toHex()
  echo result
  assert(result == "c966b463b67c6424fefebcfcd475817e379065c7", "SHA1 result did not match")

  #test sha1 - 60 char input
  result = compute("JhWAN0ZTmRS2maaZmDfLyQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toHex()
  echo result
  assert(result == "e3571af6b12bcb49c87012a5bb5fdd2bada788a4", "SHA1 result did not match")

  #test sha1 - longer input
  result = compute("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz").toHex()
  echo result
  assert(result == "f2090afe4177d6f288072a474804327d0f481ada", "SHA1 result did not match")

  #test sha1 - shorter input
  result = compute("shorter").toHex()
  echo result
  assert(result == "c966b463b67c6424fefebcfcd475817e379065c7", "SHA1 result did not match")

  #test base64 encoding
  result = compute("dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toBase64()
  echo result
  assert(result == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=", "SHA1 base64 result did not match")
