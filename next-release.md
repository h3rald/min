### BREAKING CHANGES

* Runtime checks (expectations, stack pollution checks, operator output validation) must now be manually activated by specifying `-d` or `--dev`. Activating checks can be very useful while developing a min program, at cost of performance.
* Moved the following symbols from the **sys** to the **fs** module:
  * exists?
  * dir?
  * file?
  * symlink?
  * filename
  * dirname

### New Features

* Added **dev?** symbol to check if we are running in development mode.
* Added new symbols to the **fs** module:
  * join-path
  * expand-filename
  * expand-symlink
  * normalized-path
  * absolute-path
  * relative-path
  * windows-path
  * unix-path
  * absolute-path?
* Added **admin?** symbol to the **sys** module.

### Fixes and Improvements

* Fixed Nim 1.6.0 compilation warnings.
* string values are now properly escaped when printed.
