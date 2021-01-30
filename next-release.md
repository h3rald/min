* Implemented "auto-popping" by adding **!** at the end of any symbol (#104).
* Removed all symbols ending with **!** as auto-popping will work instead.
* Improved contrast and readability of the min web site (#107).
* Extended **operator** to support the creation of constructor symbols.
* Now using **dict:http-response** and **dict:http-response** for HTTP requests/responses.
* Now using **dict:timeinfo** for time info.
* Changed **parse-url** to push a **dict:url** on the stack.
* Fixed #115 and #118.

### Breaking changes

This release also introduces quite a lot of breaking changes aiming at addressing some language inconsistencies and making the language more stable overall (see #111 for more information).

**Read this carefully! It is most likely that your code will break when you upgrade.**


* Removed **quote-define** (=) and **quote-bind** (#).
* **define** (:) now auto-quote quotations as well.
* To quickly bind a quotation to a symbol (and essentially create a symbol operator but with no validations or constraints), use the new **lambda** symbol or **^** (alias, sigil) -- addresses also #114.
* Removed **typeclass** and extended **operator** to create type classes as well.
* Renamed **string** and **float** type names (used in operator signatures) to **str** and **flt** respectively.
* Removed **define-sigil**, use **operator** instead.
* Removed **module** and **+** (sigil); use **require** to create modules.
* Removed **call**, **^** (sigil, alias -- reused for **lambda**, see above); use **invoke** to access module/dictionary symbols.
* Removed **set-type** symbol.
* Removed **~** sigil (rarely used).
* Renamed the following symbols:
  * `int` -> `integer`
  * `bool` -> `boolean`
  * `delete` -> `delete-symbol`
  * `defined?` -> `defined-symbol?`
  * `seal` -> `seal-symbol`
  * `sealed?` -> `sealed-symbol?`
  * `unseal` -> `unseal-symbol`
