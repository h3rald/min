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

## Symbols

_Symbols_ are the most common type of operator. A min symbol is a single word that is either provided by one of the predefined min {#link-page||reference||modules#} like `dup` or `.` or defined by the user. User-defined symbols must:

* Start with a letter or an underscore (\_).
* Contain zero or more letters, numbers and/or any of the following characters: `/ ! ? + * . _ -`

It is possible to define operator symbols using the {#link-operator||lang||operator#} symbol. The following min program defines a new symbol called square that duplicates the first element on the stack and multiplies the two elements:

     (
       symbol square
       (num :n ==> num :result)
       (n dup * @result)
     ) operator
     ;; Calculates the square of n.

 The {#link-operator||lang||operator#} symbol provides way to:
 
 * Specify the name of the symbol operator (**square** in this case)
 * Specify a signature to identify the type of the input and output values (in this case, the operator takes a numeric input value and produces a numeric output value). Also, note how inputs and outputs are captured into the `n` and `result` symbols in the signature quotation and then referenced in the body quotation.
 * Specify a quotation containing the code that the operator will execute.

Also, symbol operator definitions can be annotated with documentation comments (starting with `;;` or wrapped in `#|| ... ||#`)) so that a help text can be displayed using the {#link-operator||lang||help#} symbol.

### Using the lambda operator

Sometimes you just want to bind a piece of code to a symbol to reuse it later, typically something simple and easy-to-read. In these cases, you can use the {#link-operator||lang||lambda#} operator (or the `^` sigil). For example, the previous `square` operator definition could be rewritten simply as the following.

     (dup *) ^square
     
Note that this feels like using {#link-operator||lang||define#}, but the main difference between {#link-operator||lang||lambda#} and {#link-operator||lang||define#} is that `lambda` only works on quotations doesn't auto-quote them, so that they are immediately evaluated when the corresponding symbol is pushed on the stack.

Also note that unlike with {#link-operator||lang||operator#}, symbols defined with {#link-operator||lang||lambda#}:

* have no built-in validation of input and output values.
* do not support the `return` symbol to immediately end their execution.
* have no built-in stack pollution checks.

> %tip%
> Tip
> 
> You can use {#link-operator||lang||lambda-bind#} to re-set a previously set lambda.

## Sigils

Besides symbols, you can also define sigils. min provides a set of predefined _sigils_ as abbreviations for commonly used symbols. 

A sigil can be prepended to a double-quoted string or a single word (with no spaces) which will be treated as a string instead of using the corresponding symbol. 

For example, the following executes the command `ls -al` and pushes the command return code on the stack:

     !"ls -al"

Currently min provides the following sigils:

'
: Alias for {#link-operator||lang||quote#}.
\:
: Alias for {#link-operator||lang||define#}. 
*
: Alias for {#link-operator||lang||invoke#}. 
@
: Alias for {#link-operator||lang||bind#}. 
^
: Alias for {#link-operator||lang||lambda#}. 
~
: Alias for {#link-operator||lang||lambda-bind#}. 
>
: Alias for {#link-operator||lang||save-symbol#}. 
<
: Alias for {#link-operator||lang||load-symbol#}.  
/
: Alias for {#link-operator||dict||dget#}. 
%
: Alias for {#link-operator||dict||dset#}. 
?
: Alias for {#link-operator||lang||help#}.
!
: Alias for {#link-operator||sys||system#}.
&
: Alias for {#link-operator||sys||run#}.
$
: Alias for {#link-operator||sys||get-env#}. 

Besides system sigils, you can also create your own sigils. Unlike system sigils however, user defined sigils:

* have the same character restrictions as symbols
* can only be prepended to double-quoted strings
* can be unsealed, deleted, redefined, and sealed.

Sigils can be a very powerful construct and a way to reduce boilerplate code: you can define a sigil to use as you would use any symbol which requires a single string or quoted symbol on the stack.

Like symbols, sigils can be defined with the {#link-operator||lang||operator#} operator, like this:

     (
       sigil j
       (string :json ==> a :result)
       (json from-json @result)
     ) operator

This definition will add a `j` sigil that will process the following string as JSON code, so for example:

     j"{\"test\": true}"

...will push the following dictionary on the stack:

    {true :test}

Also, sigil definitions can be annotated with documentation comments (starting with `;;` or wrapped in `#|| ... ||#`) so that a help text can be displayed using the {#link-operator||lang||help#} symbol.

## Auto-popping

Typically, but not always, operators push one or more value to the stack. While this is typically the desired behavior, in some cases you may want to keep the stack clear so in these cases you can append a `!` character to any symbol to cause the symbol {#link-operator||lang||pop#} to be pushed on the stack immediately afterwards.

     "test" puts  ;Prints "test" and pushes "test" on the stack.
     "test" puts! ;Prints "test" without pushing anything on the stack.

## Operator signatures

When defining symbols and sigils with the {#link-operator||lang||operator#} operator, you must specify a *signature* that will be used to validate and capture input and output values:

     (
       symbol square
       (num :n ==> num :result)
       (n dup * @result)
     ) operator

In this case for example the `square` symbol expects a number on the stack, which will be captured to the symbol `n` and it will place a number on the stack which needs to be bound in the operator body to the symbol `result`.

In a signature, a type expression must precede the capturing symbol. Such type expression can be:

* One of the following shorthand symbols identifying a well-known {{m}} base type (see the {#link-page||reference||reference#} section for more information): `a`, `bool`, `null`, `str`, `int`, `num`, `flt`, `'sym`, `quot`, or `dict`.
* A typed dictionary like `dict:module` or `dict:datastore`.
* A type class (see below).
* a type expression like `str|int`.

> %note%
> Note
> 
> If the operator you are defining doesn't require any input value or doesn't leave ang output value on the stack, simply don't put anything before or after the `==>` separator, respectively. For example, the signature of the {#link-operator||lang||puts!#} operator could be written like `(a ==>)`.

### Type classes

Besides standard base types, you can define your own *type classes* to express custom constraints/validations for operator input and output values.

Consider the following type class definition validating a quotation containing strings:

     (
       typeclass strquot
       (quot :q ==> bool :o)
       (q (string?) all? @o)
     ) ::

The {#link-operator||lang||operator#} operator can be used to define a symbol prefixed with `typeclass:` (`typeclass:strquot` in this case) corresponding to a type class that can be used in operator signatures in place of a type, like this:

     (
       symbol join-strings
       (strquot :q ==> str :result)
       ( 
          q "" (suffix) reduce @result
       )
     )

This operator will raise an error if anything other than a quotation of strings is found on the stack.

> %tip%
> Tip
> 
> `typeclass:`-prefixed symbols are just like ordinary symbols: they are lexically scoped, they can be sealed, unsealed and deleted.

#### Capturing lambdas

You can also specify a lambda to be captured to an output value, like this:

     (
       symbol square
       (==> quot ^o)
       (
         (dup *) ~o
       )
     ) ::
     
Essentially, this allows you to push a lambda on the stack from an operator.

Note that:

* Lambdas must be captured using the `^` sigil in signatures and bound using {#link-operator||lang||lambda-bind#} in the operator body.
* Lambdas cannot be captured in input values (they have already been pushed on the stack).
* Requiring a lambda as an output value effectively bypasses stack pollution checks. While this can be useful at times, use with caution!

### Type expressions

When specifying types in operator signatures or through the {#link-operator||lang||expect#} operator, you can specify a logical expression containing types and type classes joined with one of the following operators:

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

As you can see, type expressions can quickly become quite long and complex. To avoid this, you can define *type aliases* using the {#link-operator||lang||typealias#} operator. 

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

### Generics

{{m}} supports generics in operator signatures. in other words, you can define a custom type alias on-the-fly directly in an operator signature, like this:

```
(
  symbol add
  ((str|num|quot :t) :a t :b ==> t :result)
  (
   (a type "str" ==)
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

In this case, `t` is set to the type union `stribg|num|quot`, and the `add` method above can be used to sum two numbers or join two strings or quotations.

Note that the value of `t` is evaluated to the type of the first value that is processed. In other words, the following programs will work as expected:

     3 5 add ;outputs 8
     
     "hello, " "world" ;outputs "hello, world"

while the following will raise an error, because the value of `t` from `num` to `quot` within the same operator use:

     12 "test" add ;raises an error
     
> %sidebar%
> Generics vs type unions
>
> Generics allow to specify a type as a type union, but the type will remain the same one throughout the same operator call. 
> By contrast, using the same type union several times within the same signature allows different types to be used in the same call, and that is probably something you don't want!

### Constructors

The {#link-operator||lang||operator#} operator can also be used to create *constructor* symbols. A constructor is a particular type of operator that is used to create a new typed dictionary.

Consider the following example:

     (
       constructor point
       (num :x num :y ==> dict :out)
       (
         {}
           x %x
           y %y
         @out
       )
     ) ::
     
The operator above creates a `point` constructor symbol that can be used to create a new `dict:point` typed dictionary by popping two numbers from the stack:

     2 3 point ; {2 :x 3 :y ;point}
     
> %note%
> Tip
>
> Except for some native symbols, constructors represent the only way to create new typed dictionaries. The more validations you perform in a constructor, the most effective checking for a specific type using the {#link-operator||logic||type?#} operator will be, as `type?` only checks if a specific type annotation is present on a typed dictionary, nothing else.

{#link-learn||quotations||Quotations#}
