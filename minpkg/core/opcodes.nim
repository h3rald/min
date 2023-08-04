

type MinOpCode* = enum
  opUndef = 0x00   # Undefined
  #### Header
  opHead = 0x01    # Header
                   # 9 bytes in total
                   # language: 3
                   # version:  3
                   # bytecode: 1
                   # undefined:2

  #### Start
  opStart = 0x02   # Program start

  #### Literal Values
  opPushIn = 0x11  # Push integer value
                   # value:    8
  opPushFl = 0x12  # Push float value
                   # value:    8
  opPushNl = 0x13  # Push null value
  opPushTr = 0x14  # Push true value
  opPushFa = 0x15  # Push false value
  opStrBeg = 0x16  # Begin string
  OpStrEnd = 0x17  # End String
  OpQuotBeg = 0x18 # Begin quotation
  OpQuotEnd = 0x19 # End quotation
  OpDictBeg = 0x1A # Begin dictionary
                   # typelength: 2
                   # typevalue: ...
  OpDictEnd = 0x1B # End dictionary
  OptCmdBeg = 0x1C # Begin command
  OptCmdEnd = 0x1D # End command

  #### Symbols
  opSym = 0x20     # Push symbol
                   # length: 2
                   # value: ...
  #### Stop
  opStop = 0xFF    # Program stop


