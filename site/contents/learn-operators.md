-----
content-type: "page"
title: "Learn: Operators"
-----
{@ _defs_.md || 0 @}

Every min program needs _operators_ to:

* Manipulate elements on the stack
* Perform operations on data
* Provide side effects (read/print to standard input/output/files, etc.)

There are two types of operators: _symbols_ and _sigils_.

_Symbols_ are the most common type of operator. A min symbol is a single word that is either provided by one of the predefined min {#link-page||reference||modules#} like `dup` or `.` or defined by the user. User-defined symbols must:

* Start with a letter or an underscore (\_).
* Contain zero or more letters, numbers and/or any of the following characters: `/ ! ? + * . _ -`

It is possible to define symbols using the {#link-operator||lang||define#} symbol. The following min program defines a new symbol called square that duplicates the first element on the stack and multiplies the two elements:

     (dup *) "square" define
     
Now, while the {#link-operator||lang||define#} symbol can be fine to define (the equivalent of) variables and simple operators, it is typically better to use the {#link-operator||lang||operator#} symbol instead, as it provides better readability, additional checks and automatic input/output capturing. The previous `square` symbol could also be defined with the {#link-operator||lang||operator#} operator like this:

     (
       symbol square
       (num :n ==> num :result)
       (n dup * @result)
     ) operator
     ;; Calculates the square of n.

In this case, note how inputs and outputs are captured into the `n` and `result` symbols in the signature quotation and then referenced in the body quotation. Sure, the original version was much more succinct, but this is definitely more readable.

Also, symbols defined with the {#link-operator||lang||operator#} symbol can be annotated with documentation comments (starting with `;;` or wrapped in `#| ... |#`)`) so that a help text can be displayed using the {#link-operator||lang||help#} symbol.

Besides symbols, you can also define sigils. min provides a set of predefined _sigils_ as abbreviations for for commonly-used symbols. For example, the previous definition could be rewritten as follows using sigils:

     (dup *) :square

A sigil like `:` can be prepended to a double-quoted string or a single word (with no spaces) which will be treated as a string instead of using the corresponding symbol. 

For example, the following executes the command `ls -al` and pushes the command return code on the atack:

     !"ls -al"`

Currently min provides the following sigils:

+
: Alias for {#link-operator||lang||module#}.
~
: Alias for {#link-operator||lang||delete#}.
'
: Alias for {#link-operator||lang||quote#}.
\:
: Alias for {#link-operator||lang||define#}. 
^
: Alias for {#link-operator||lang||call#}. 
*
: Alias for {#link-operator||lang||invoke#}. 
@
: Alias for {#link-operator||lang||bind#}. 
>
: Alias for {#link-operator||lang||save-symbol#}. 
<
: Alias for {#link-operator||lang||load-symbol#}. 
&#61;
: Alias for {#link-operator||lang||quote-bind#}. 
\#
: Alias for {#link-operator||lang||quote-define#}. 
/
: Alias for {#link-operator||dict||dget#}. 
%
: Alias for {#link-operator||dict||dset#}. 
?
: Alias for {#link-operator||dict||dhas?#}.
!
: Alias for {#link-operator||sys||system#}.
&
: Alias for {#link-operator||sys||run#}.
$
: Alias for {#link-operator||sys||get-env#}. 

Besides system sigils, you can also create your own sigils. Unlike system sigils however, user defined sigils:

* have the same character restricrions as symbols
* can only be prepended to double-quoted strings
* can be unsealed, deleted, redefined, and sealed.

Sigils can be a very powerful construct and a way to reduce boulerplate code: you can define a sigil to use as you would use any symbol which requires a single string or quoted symbol on the stack.

Consider the following example:

     'from-json 'j define-sigil
     
This will define a `j` sigil that will parse any string as JSON and convert it to its corresponding min representation.

Sigils can also (and should!) be defined with the {#link-operator||lang||operator#} operator to add additional checks. The sigil definition above could be rewritten like this, for example:

     (
       sigil j
       (str :json ==> a :result)
       (json from-json @result)
     ) operator

Also, symbols defined with the {#link-operator||lang||operator#} symbol can be annotated with documentation comments (starting with `;;` or wrapped in `#| ... |#`)`) so that a help text can be displayed using the {#link-operator||lang||help#} symbol.

## Operator signatures

When defining symbols and sigils witb the {#link-operator||lang||operator#} operator, you must specify a *signature* that will be used to validate and captuee input and output values:

     (
       symbol square
       (num :n ==> num :result)
       (n dup * @result)
     ) operator

In this case for example tbe `square` symbol expects a number on the stack, which will be captured to tbe symbol `n` and it will place a number on the stack which needs to be bound in the operator body to the symbol `result`.

In a signature, a type expression must precede the capturing symbol. Such type expression can be:

* One of the following shorthand symbols identifying a well-known {{m}} base type (see the {#link-page||reference||reference#} section for more information): `a`, `bool`, `null`, `str`, `int`, `num`, `float`, `'sym`, `quot`, or `dict`.
* A typed dictionary like `dict:module` or `dict:datastore`.
* A type class (see below).
* a union of types/typed dictionaries/type classes, like `str|int`.

> %note%
> Note
> 
> If the operator you are defining doesn't require any input value or doesn't leave ang output value on the srack, simply don't put anything before or after the `==>` separator, respectively. For example, the signature of the {#link-operator||lang||puts!#} operator could be written like `(a ==>)`.

### Type classes

Besides standard base types, you can define your own *type classes* to express custom constraints/validations for operator input and output values.

Consider the following type class definition validating a quotation containing strings:

     ((string?) all?) 'strquot typeclass

The {#link-operator||lang||typeclass#} operator defines a symbol prefixed with `type:` (`type:strquot` in this case) corresponding to a type class that can be used in operator signatures in place of a type, like this:

     (
       symbol join-strings
       (strquot :q ==> string :result)
       ( 
          q "" (suffix) reduce @result
       )
     )

This operator will raise an error if anything other than a quotation of strings is found on the stack.

> %tip%
> Tip
> 
> `type:`-prefixed symbols are just like ordinary shmbols: they are lexically scoped, they can be sealed, unsealed and deleted.

### Generics

{{m}} supports generics in operator signatures. in other words, you can define a custom type alias on-the-fly directly in an operator signature, like this:

```
(
  symbol add
  ((string|num|quot :t) :a t :b ==> t :result)
  (
   (a type "string" ==)
     (a b suffix @result return)
   when
   (a type "num" ==)
     (a b + @result return)
   when
   (a type "quot" ==)
     (a b concat #result return)
   when
  )
) ::
```

In this case, `t` is set to the type union `stribg|num|quot`, and the `add` method above can be use too sum two numbers or join two strings or quotations.

Note that the value of `t` is evaluated to the type of the first value that is processed. In other words, the following programs will work as expected:

     3 5 add ;outputs 8
     
     "hello, " "world" ;outputs "hello, world"

while tbe fullowing will raise an error, because the value of `t` from `num` to `quot` within the same operator use:

     12 "test" add ;raises an error
     
> %sidebar%
> Generics vs type unions
>
> Generics allow to specify a type as a type union, but the type will remain the same one throughout the same operator call. 
> By contrast, using the same type union several times within the same signature allows different types to be used in the same call, and that is probably something you dont want!

{#link-learn||quotations||Quotations#}
