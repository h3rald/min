### Breaking changes

* #141 - The **'** symbol is now an alias of the **quotesym** symbol (but its behavior remains the same: it can be used to created quotes symbols from a string), and the **'** sigil is equivalent to the new **quotesym** symbol, not **quote**.

### Fixes

* #147 - Fixed an error when processing operator output values.
* Now adding **help.json** to installation folder when installing via nimble.
* #151 - Added documentation for **integer**.
* #152 - Now preventing infinite recursion in case a symbol evaluates to itsel.

### New features

* #144 - The symbol **type?** is now able to check if a value satisfies a type expression, not only a simple type. Note however that it is now necessary to prepend dictionary types with `dict:` (as in type expressions).
* #141 - A new **quotesym** symbol has been added to transform a string into a quoted symbol. This is equivalent to the behavior of the **'** sigil.
