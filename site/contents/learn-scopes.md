-----
content-type: "page"
title: "Scopes"
-----
{@ _defs_.md || 0 @}

As explained in [Definitions](/learn-definitions), min uses lexical scoping to resolve symbol. A *scope* is an execution context (a symbol table really) that:
* is created while a a new quotation is being dequoted or a dictiionary is created.
* is destroyed after a quotation has been dequoted.
* is attached to a dictionary.

The main, root-level scope in min can be accessed using the {#link-operator||lang||ROOT#} symbol and it typically contains all symbols and sigils imported from all the standard library modules. The ROOT symbol pushes a module on the stack that references the ROOT scope:

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt) ROOT
>   {
>    &lt;native&gt; :!
>    &lt;native&gt; :!=
>    ...
>    &lt;native&gt; :xor
>    &lt;native&gt; :zip
>    ;module
>   }

> %note%
> Note
>
> &lt;native&gt; values cannot be retrieved using the {#link-operator||dict||dget#} operator.

## Accessing the current scope

You can access the current scope using the {#link-operator||lang||scope#} operator, which pushes a module on the stack that references the current scope.

Consider the following program:

     {} :innerscope ("This is a test" :test scope @myscope) -> myscope scope-symbols

In this case:

1. A new variable called `innerscope` is defined on the ROOT scope.
2. A quotation is dequoted, but its scope is retrieved using the `scope` operator and bound to `innerscope`.
3. After the quotation is dequoted, myscope is accessed and its symbols (`test` in this case) are pushed on the stack using the {#link-operator||lang||scope-symbols#} operator.

Note that scopes can only be accessed if they are bound to a dictionary, hence the `ROOT` and `scope` operators push a module on the stack, and a module is nothing but a typed dictionary.

## Dequoting a quotation within the context of a specific scope

The {#link-operator||lang||with#} operator can be used to dequote a quotation within a specific scope instead of the current one.

Consider the following program, which leaves `2` on the stack:

     (4 2 minus) {'- :minus} with ->

In this case, when `with` is pushed on the stack, it will dequote `(4 2 minus)`. Note that the symbol `minus` is defined in the dictionary that will be used by `with` as the current scope, so after `with` is pushed on the stack, the stack contents are:

     4 2 (-)

At this points, the {#link-operator||lang||dequote#} operator is pushed on the stack and the subtraction is executed leaving `2` on the stack.

{#link-learn||control-flow||Control Flow#}
