### New Features

* Added support for binary (0b) octal (0o), and hexadecimal (0x) integers in parser.
* Added `base` and `base?` symbols to set and get the current number base (dec, hex, bin or oct).
* Added `bitand`, `bitor`, `bitxor`, `bitparity`, `bitclear`, `bitflip`, `bitset`, `bitmask` symbols for biwise operations.
* Added `to-(hex|bin|dec|oct)` and `from-(hex|bin|dec|oct)` symbols to convert integers to and from different string representations.

### Fixes and Improvements

* Now requiring `checksums` unless OpenSSL is used.
* Prepended `std/` to standard library modules.
