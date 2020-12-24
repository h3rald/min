* Added **encode-url**, **decode-url**, **parse-url** symbols.
* Added **dstore**  module providing support for simple, persistent, in-memory JSON stores.
* Added **require** symbol to read a min file and automatically create a module containing all symbols defined in the file.
* Added **invoke** symbol (and **\*** sigil) to easily call a symbol defined in a module or dictionary, e.g. `*mymodule/mymethod`.
* Fixed library installation via nimble
* Fixed error handling and stack trace for **start-server** symbol.
* Added the possibility to bundle assets in a compiled min program by specifying tbe **-a** (or **--asset-path**) option.
* Added **expect-empty-stack** (**=-=**) symbol.
