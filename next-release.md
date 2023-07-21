### New Features 

* min is now a superset of [mn](https://h3rald.com/mn):
    * Implemented support for executing commands by wrapping strings in `[ ]`, like in mn.
    * Implemented new `quotecmd` symbol to quote command strings.
    * Implement aliases for compatibility with _mn_: `getstack` (`get-stack`), `setstack` (`set-stack`), `lambdabind` (`lambda-bind`), `read` (`fread`), `write` (`fwrite`).

### Fixes and Improvements

* Documentation improvements and fixes (thanjs @agentofuser, @tristanmcd130, and @jo-he).
* Fixed #184 (thanks @inivekin).
* Fixed problem with hardcoded relative paths to third-party libraries that prevented installing via nimble.
* Removed filename/line/column from generated Nim code when compiling.
* Upgraded OpenSSL to v3.1.1.
