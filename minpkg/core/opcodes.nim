

type MinOpCode* = enum

  opUndef = 0x00  # Terminator/Undefined
  #### Header
  opHead = 0x01   # Header
                  # 9 bytes in total
                  # language: 3
                  # version:  3
                  # bytecode: 1
                  # undefined:2

  #### Start
  opStart = 0x02  # Program start

  #### Literal Values
  opPushIn = 0x11 # Push integer value
                  # value:    8
  opPushFl = 0x12 # Push float value
                  # value:    8
  opPushNl = 0x13 # Push null value
  opPushTr = 0x14 # Push true value
  opPushFa = 0x15 # Push false value
  opStr = 0x16    # Begin string
  OpQuot = 0x17   # Begin quotation
  OpDict = 0x18   # Begin dictionary
                  # type: ... 0
  OptCmd = 0x19   # Begin command

  #### Symbols
  opSym = 0x20    # Begin symbol
                  # value: ... 0
  #### Stop
  opStop = 0xFF   # Program stop


