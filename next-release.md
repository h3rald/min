* Improved diagnostics for native symbols calling other symbols.
* Refactored **crypto** module to use Nim StdLib's md5 and sha1 module when OpenSSL support is not enabled.
* Fixed detection of musl executables when running build task.
* Added **union**, **intersection**, **difference**, **symmetric-difference**, **one?** symbols to **seq** module.
* Fixed compilation for loaded files and assets.
* Refacored code to satisfy nimble package structure.
* Now caching required modules so that their code is executed only once.
* Added **line-info** symbol returning a dictionary containing the current filename, line and column numbers.
* Added **dsdelete!**, **dspost!**, **dsput!**, **dswrite!**.
