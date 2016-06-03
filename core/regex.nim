import strutils
import ../vendor/sgregex


proc match*(str, pattern, mods: string): bool =
  let r = srx_Create(pattern, mods)
  result = srx_Match(r, str, 0) == 1
  discard srx_Destroy(r)

proc match*(str, pattern: string): bool =
  return match(str, pattern, "")

proc search*(str, pattern, mods: string): seq[string] =
  let r = srx_Create(pattern, mods)
  discard srx_Match(r, str, 0) == 1
  let count = srx_GetCaptureCount(r)
  result = newSeq[string](count)
  for i in 0..count-1:
    var first = 0
    var last = 0
    discard srx_GetCaptured(r, i, addr first, addr last)
    result[i] = str.substr(first, last-1)
  discard srx_Destroy(r)

proc search*(str, pattern: string): seq[string] =
  return search(str, pattern, "")

proc replace*(str, pattern, repl, mods: string): string =
  var r = srx_Create(pattern, mods)
  result = $srx_Replace(r, str, repl)
  discard srx_Destroy(r)

proc replace*(str, pattern, repl: string): string =
  return replace(str, pattern, repl, "")

proc `=~`*(str, r: string): seq[string] =
  let m = r.search("(s)?/(.+?)/((.+?)/)?([mis]{0,3})?")
  # full match, s, reg, replace/, replace, flags
  if m[1] == "s" and m[3] != "":
    return @[replace(str, m[2], m[4], m[5])]
  else:
    return search(str, m[2], m[5])

when isMainModule:

  proc tmatch(str, pattern: string) =
    echo str, " =~ ", "/", pattern, "/", " -> ", str.match(pattern)

  proc tsearch(str, pattern: string) =
    echo str, " =~ ", "/", pattern, "/", " -> ", str.search(pattern)

  proc tsearch(str, pattern, mods: string) =
    echo str, " =~ ", "/", pattern, "/", mods, " -> ", str.search(pattern, mods)

  proc treplace(str, pattern, repl: string) =
    echo str, " =~ ", "s/", pattern, "/", repl, "/", " -> ", str.replace(pattern, repl)

  proc toperator(str, pattern: string) =
    echo str, " =~ ", pattern, " -> ", str =~ pattern

  "HELLO".tmatch("^H(.*)O$")
  "HELLO".tmatch("^H(.*)S$")
  "HELLO".tsearch("^H(E)(.*)O$")
  "Hello, World!".treplace("[a-zA-Z]+,", "Goodbye,")
  "127.0.0.1".tsearch("^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})$")
  "127.0.0.1".treplace("^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})$", "$4.$3.$1.$2")
  "127.0.0.1".treplace("[0-9]+", "255")
  "Hello".tsearch("HELLO", "i")
  "Hello\nWorld!".tsearch("HELLO.WORLD", "mis")
  "Testing".toperator("s/test/eat/i")
  

