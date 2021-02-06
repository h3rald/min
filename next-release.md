
### Fixes

* Added `===` at the end of integrated help descriptions (#127).
* Fixed override propagation when setting isymbols in upper scopes (#133).

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

#### Type Expressions

When specifying types in operator signatures or through the {#link-operator||lang||expect#} operator, you can specify a logical expression containing types and type classes joined with one kf the following operators:

* `|` (or)
* `&` (and)
* `!` (not)

Suppose for example you defined the following type classes:

```
(typeclass fiveplus
    (int :n ==> bool :o)
    (
      n 5 > @o
    )
) ::

(typeclass tenminus
    (int :n ==> bool :o)
    (
      n 10 < @o
    )
) ::

(typeclass even
    (int :n ==> bool :o)
    (
      n 2 mod 0 == @o
    )
) ::
```

You can combine them in a type expression as following:

```
(symbol test
    (!even|tenminus&fiveplus :n ==> bool :o)
    (
      true @o
    )
) ::
4 test  ; error
6 test  ; true
11 test ; true 
```

### Type aliases

You can definenow  *type aliases* using the {#link-operator||lang||typealias#} operator. Mmmm

For example, you can create an alias of part of the type expression used in the previous example, like this:

```
'tenminus&fiveplus 'five-to-ten typealias

(symbol test
    (!even|five-to-ten :n ==> bool :o)
    (
      true @o
    )
) ::
```

Note that:
* Type aliases be used to create an alias for any type expression.
* Aliased type expressions can contain standard {{m}} types, dictionary types, type classes, and even other type aliases.
* The {#link-operator||lang||typealias#} operator actually creates lexically-scoped, `typealias:`-prefixed symbols that can be sealed, unsealed, and deleted exactly like other symbols.
