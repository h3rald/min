### BREAKING CHANGES

- User-defined symbols can no longer contain dots (`.`).
- The symbol `invoke` and the `*` sigil have been removed in favor of symbol dot notation.
- The `.` and `..` symbols have been renamed to `pwd` and `parent-dir` respectively.

### New Features

- It is now possible to access dictionary (and module) keys (even nested) via dot notation. This replaces the `invoke` symbol.
- Added shell auto-completion for symbols using dot notation
- Added a new `color` symbol to the `io` module to enable/disable terminal color output.
- Added a new `from-html` symbol to the `xml` module to parse HTML documents and fragments.
- Added a new `xentity2utf8` symbol to the `xml` module to convert an XML entity to its corresponding UTF-8 string.
- Added a new `xescape` symbol to the `xml` module to convert special XML characters into the corresponding XML entities.

### Fixes and Improvements

- Fixed `tokenize` symbol (wasn't processing commands correctly)

