{@ _defs_.md || 0 @}

{{learn-links}}

*min* is a stack-based, concatenative programming language that uses postfix notation. If you already know [Forth](http://www.forth.org/), [Factor](http://factorcode.org/) or [Joy](http://www.kevinalbrecht.com/code/joy-mirror/), or if you ever used an [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation) calculator, then min will look somewhat familiar to you. 

If not, well, here's how a short min program looks like:

    (1 2 3 4 5) (dup *) map

This program returns a list containing the square values of the first five integer numbers:

    (1 4 9 16 25)

Let's see how it works:

1. First a list containing the first five integer is pushed on the stack.
2. Then, another list containing two symbols (`dup` and `\*`) is pushed on the stack. This constitutes a quoted program which, when executed duplicates (`dup`) the first element on the stack and then multiplies (`*`) the two elements together.
3. Finally, the symbol `map` is pushed on the stack. Map takes a list of elements and a quoted program and applies the program to each element.

Note that:

* There are no variable assignments.
* elements are pushed on the stack one by one.
* Parentheses are grouped together one or more elements, so that they are treated as a single element and they are not evaluated immediately.
* Symbols can be used to perform operations on the whole stack.

Unlike more traditional programming languages, in a concatenative programming language there is no inherent need of variables or named parameters, as symbols acts as stack operators that consume elements that are placed in order on top of a stack.

{#link-learn||data-types||Data Types#}
