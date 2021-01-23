* Added support for Scheme-style block comments using hashpipe style: `#| ... |#`.
* Implemented support for documentation comments (`;;` or `#|| ... ||#`) placed right after an operator definition.
* **BREAKING CHANGE** -- **?** is now used as a sigil for **help**, not **dget**.
* Added **help** (and also **?** alias and **?** sigil), **symbol-help**, **sigil-help**
* Added **replace-apply** and **search-all**.
* Refactored tasks as required modules.
* Added binary operators to num module (thanks @drkameleon!).
* Added **product**, **med**, **avg** and **range** operators to num module (thanks @drkameleon!).
* Added Dockerfile (thanks @drkameleon!).
