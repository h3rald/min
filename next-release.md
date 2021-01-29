* Implemented "auto-popping" by adding **!** at the end of any symbol.
* Removed all symbols ending with **!** as auto-popping will work instead.
* Improved contrast and readability of the min web site.
* Removed **typeclass** and extended **operator** to create tupe classes as well.
* Renamed **string** and **float** type names (used in operator signatures) to **str** and **flt** respectively.
* Removed **define-sigil**, use **operator** instead.
* Removed **module** and **+** (sigil); use **require** to create modules.
* Removed **call**, **^** (sigil, alias); use **invoke** to access module/dictionary symbols.
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
