
### Fixes

* Added `===` at the end of integrated help descriptions (#127).

### Mew additions
 
* New symbol: [parent-scope](https://min-lang.org/reference-lang/#op-parent-scope) (#117).

### Notable changes

#### Lambda capturing in operator output values

You can now specify a lambda to be captured to an output value, like this:

     (
       symbol square
       (==> quot ^o)
       (
         (dup *) ~o
       )
     ) ::
     
Essentially, this allows you to push a lambda on the stack from an operator.

Note that:
* Lambdas must be captured using the `^` sigil in signatures and bound using `lambda-bind` in the operator body.
* Lambdas cannot be captured in input values (they have already been pushed on the stack).
* Requiring a lambda as an output value effectively bypasses stack pollution checks. While this can be useful at times, use with caution!
