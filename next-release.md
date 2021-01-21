* Added support for Scheme-style block comments using hashpipe style: `#| ... |#`.
* Implemented support for documentation comments (`;;` or `#|| ... ||#`) placed right after an operator definition.
* **BREAKING CHANGE** -- **?** is now used as a sigil for **help**, not **dget**.
* Added **help** (and also **?** alias and **?** sigil), **symbol-help**, **sigil-help**
* Added **replace-apply**.
* Refactored tasks as required modules.
