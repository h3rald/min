import
    strutils,
    sequtils

import
    meta,
    baseutils,
    parser,
    interpreter,
    opcodes

proc newVM*(): MinVm =
    result.interpreter = newMinInterpreter("<vm>")

proc bytecode(s: string, symbol = false): seq[byte] =
    result = newSeq[byte](0)
    if symbol:
        result.add opSym.byte
        result.add s.len.byte
        for c in s:
            result.add c.ord.byte
    else:
        result.add opStrBeg.byte
        for c in s:
            result.add c.ord.byte
        result.add OpStrEnd.byte

proc bytecode(n: BiggestInt): seq[byte] =
    result = newSeq[byte](0)
    result.add opPushIn.byte
    result = result.concat(cast[array[0..7, byte]](n).toSeq)

proc bytecode(n: BiggestFloat): seq[byte] =
    result = newSeq[byte](0)
    result.add opPushFl.byte
    result = result.concat(cast[array[0..7, byte]](n).toSeq)

proc compileToBytecode*(vm: MinVm, s = ""): seq[byte] =
    result = newSeq[byte](0)
    result.add opHead.byte
    for c in pkgName:
        result.add c.ord.byte
    let v = pkgVersion.split(".")
    result.add v[0].parseInt.byte
    result.add v[1].parseInt.byte
    result.add v[2].parseInt.byte
    result.add opUndef.byte
    result.add opUndef.byte
    var p = vm.parser
    case p.token:
    of tkNull:
        result.add opPushNl.byte
        discard p.getToken()
    of tkTrue:
        result.add opPushTr.byte
        discard p.getToken()
    of tkFalse:
        result.add opPushFa.byte
        discard p.getToken()
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


proc printBytecode*(vm: MinVm, code: seq[byte]) =
    for b in code:
        echo b.toHex


