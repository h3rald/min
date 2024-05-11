### BREAKING CHANGES

- User-defined symbols can no longer contain dots (`.`).


### New Features

- Added a new `color` symbol to the `io` module to enable/disable terminal color output.
- Added a new `from-html` symbol to the `xml` module to parse HTML documents and fragments.
- Added a new `xentity2utf8` symbol to the `xml` module to convert an XML entity to its corresponding UTF-8 string.
- Added a new `xescape` symbol to the `xml` module to convert special XML characters into the corresponding XML entities.

### Fixes and Improvements

- Fixed `tokenize` symbol (wasn't processing commands correctly)

