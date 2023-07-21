import min
MINCOMPILED = true
var i = newMinInterpreter("cmdTest.min")
i.stdLib()
### cmdTest.min (main)
i.push MinValue(kind: minCommand, cmdVal: "ls")
i.push MinValue(kind: minString, strVal: "\n")
i.push MinValue(kind: minSymbol, symVal: "split", column: 15, line: 1, filename: "cmdTest.min")
i.push MinValue(kind: minSymbol, symVal: "puts", column: 20, line: 1, filename: "cmdTest.min")