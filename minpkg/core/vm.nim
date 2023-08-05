import
    strutils,
    sequtils,
    logging

import
    meta,
    baseutils,
    parser,
    interpreter,
    opcodes

proc toHex*(code: seq[byte]): string =
    code.mapIt(it.toHex).join()

proc bytecode(s: string, symbol = false): seq[byte] =
    result = newSeq[byte](0)
    if symbol:
        result.add opSym.byte
    else:
        result.add opStr.byte
    for c in s:
        result.add c.ord.byte
    result.add opUndef.byte
    var t = "string"
    if symbol:
        t = "symbol"
    logging.debug("$# {$#} $#" % [t, s, result.toHex])

when cpuEndian == littleEndian:
    proc bytecode(n: BiggestInt): seq[byte] =
        result = newSeq[byte](0)
        result.add opPushIn.byte
        result = result.concat(cast[array[0..7, byte]](n).toSeq)
        logging.debug("integer {$#} $#" % [$n, result.toHex])

    proc bytecode(n: BiggestFloat): seq[byte] =
        result = newSeq[byte](0)
        result.add opPushFl.byte
        result = result.concat(cast[array[0..7, byte]](n).toSeq)
        logging.debug("float {$#} $#" % [$n, result.toHex])
else:
    import algorithm

    proc bytecode(n: BiggestInt): seq[byte] =
        result = newSeq[byte](0)
        result.add opPushIn.byte
        result = result.concat(cast[array[0..7, byte]](n).toSeq)
        result.reverse()
        logging.debug("integer {$#} $#" % [$n, result.toHex])

    proc bytecode(n: BiggestFloat): seq[byte] =
        result = newSeq[byte](0)
        result.add opPushFl.byte
        result = result.concat(cast[array[0..7, byte]](n).toSeq)
        result.reverse()
        logging.debug("float {$#} $#" % [$n, result.toHex])

proc generateBytecodeForToken*(p: var MinParser): seq[byte] =
    case p.token:
    of tkNull:
        result.add opPushNl.byte
        discard p.getToken()
        logging.debug("null: ", opPushFa.byte.toHex)
    of tkTrue:
        result.add opPushTr.byte
        discard p.getToken()
        logging.debug("true: ", opPushFa.byte.toHex)
    of tkFalse:
        result.add opPushFa.byte
        discard p.getToken()
        logging.debug("false: ", opPushFa.byte.toHex)
    of tkInt:
        result = result.concat(p.a.parseInt.bytecode)
        p.a = ""
        discard p.getToken()
    of tkFloat:
        result = result.concat(p.a.parseFloat.bytecode)
        p.a = ""
        discard p.getToken()
    of tkString:
        result = result.concat(p.a.escapeEx.bytecode)
        p.a = ""
        discard p.getToken()
    of tkSymbol:
        result = result.concat(p.a.escapeEx.bytecode(true))
        p.a = ""
        discard p.getToken()
    else:
        raiseUndefined(p, "Undefined value: '"&p.a&"'")

proc rawBytecodeCompile*(i: In, indent = ""): seq[byte] {.discardable.} =
    result.add opHead.byte
    for c in pkgName:
        result.add c.ord.byte
    let v = pkgVersion.split(".")
    result.add v[0].parseInt.byte
    result.add v[1].parseInt.byte
    result.add v[2].parseInt.byte
    result.add opUndef.byte
    result.add opUndef.byte
    logging.debug("header: ", result.toHex)
    discard i.parser.getToken()
    while i.parser.token != tkEof:
        if i.trace.len == 0:
            i.stackcopy = i.stack
        result = result.concat(i.parser.generateBytecodeForToken())


