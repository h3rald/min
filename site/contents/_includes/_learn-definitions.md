{@ _defs_.md || 0 @}

Being a concatenative language, min does not really need named parameters or variables: simbols just pop elements off the main stack in order, and that's normally enough. There is however one small problem witht the traditional concatenative paradigm; consider the following program for example:

     dup dup 
     "\.zip$" match 
     swap fsize 1000000 > and 
     swap mtime now 3600 - >

This program takes a single string corresponding to a file path and returns true if it's a .zip file bigger than 1MB that was modified in the last how. Sure, it is remarkable that no variables are needed for such a program, but it is not very readable: because no variables are used, it is often necessary to make copies of elements and push them to the end of the stack -- that's what the {#link-operator||stack||dup#} and {#link-operator||stack||swap#} are used for.

The good news is that you can use the {#link-operator||lang||define#} operator and the `:` sigil to define new symbols, and symbols can also be set to literals of course.

Consider the following program:

     :filepath
     filepath "\.zip$" match
     filepath fsize 1000000 >
     filepath mtime now 3600 - >
     and and

In this case, the `filepath` symbol is defined and then used on the following three lines, each of which defines a condition to be evaluated. The last line contains just two {#link-operator||logic||and#} symbols necessary to compare the three conditions.


## Lexical scoping and binding

min, like many other programming languages, uses [lexical scoping](https://en.wikipedia.org/wiki/Scope_(computer_science)#Lexical_scope_vs._dynamic_scope) to resolve symbols.

Consider the following program:


     4 :a
     ( 
       a 3 + :a
       (
          a 1 + :a
          (a dup * :a) dequote
       ) dequote
     ) dequote

...What is the value of the symbol `a` after executing it? 

Simple: `4`. Every quotation defines its own scope, and in each scope a new variable called `a` is defined. In the innermost scope containing the quotation `(a dup * :a)` the value of `a` is set to `64`, but this value is not propagated to the outer scopes. Note also that the value of `a` in the innermost scope is first retrieved from the outer scope (8).

If we want to change the value of the original `a` symbol defined in the outermost scope, we have to use the {#link-operator||lang||bind#} or its shorthand sigil `@`, so that the programs becomes the following:

     4 :a ;First definition of the symbol a in the outermost scope
     (
       a 3 + @a ;The value of a is updated to 7.
       (
         a 1 + @a ;The value of a is updated to 8
         (a dup * @a) dequote ;The value of a is updated to 64
       ) dequote
     ) dequote

## quote-define and quote-bind

So far, we saw how to use the {#link-operator||lang||define#} and {#link-operator||lang||bind#} operator (or better, their shorthand sigils `:` and `@`) to define new symbols or bind values to existing ones.

Consider the following example:

     (1 2 3 4 5) :my-list
     my-list (dup *) map

If run the program above in min shell by pasting the first and then the second line in it, you'll get an error similar to the following:

     (!) <repl>(1,19) [map]: Incorrect values found on the stack:
     - expected: {top} quot quot {bottom}
     - got:      {top} quot int {bottom}
         <repl>(1,19) in symbol: map

This error says that when the {#link-operator||lang||map#} operator was evaluated, there were incorrect values on the stack. Two quotations were expected, but instead a quotation and an integer were found. How did this happen? 

Basically, when `my-list` was pushed on the stack, it pushed all its item on top of the stack. If you run {#link-operator||stack||get-stack#}, it will return the following list:

     (1 2 3 4 5 (dup *))

This happens because by default min assumes that when you define a quotation you want to define a new operator rather than a list. The following program works as expected, and it returns a list containing the squares of the first five integer numbers:

     (dup *) :square
     (1 2 3 4 5) (square) map

To avoid this behavior -- i.e. whenever you want to define a list of items rather than an operator that will be immediately evaluated when pushed on the stack, you have to use the {#link-operator||lang||quote-define#} and the {#link-operator||lang||quote-bind#} or their respective sigils `#` and `=`:

     (1 2 3 4 5) #my-list
     my-list (dup *) map ;Returns (1 4 9 16 25) 

## Sealing symbols

Finally, symbols can be sealed to pervent accidental updates or deletions. By default, all symbols defined in the core min modules are sealed, so the following code if run in min shell will result in an error:


     5 :quote

...because the symbol quote is already defned in the root scope. However, note that the folliwng code will _not_ return an error:

     (5 :quote quote dup *) -> ;returns 25

...because the `quote` symbol is only defined in the root scope and can therefore be redefined in child scopes.

If you want, you can {#link-operator||lang||seal#} your own symbols so that they may not be redefined using the {#link-operator||lang||bind#} operator or deleted using the {#link-operator||lang||delete#}.

> %info%
> Note
> 
> The {#link-operator||lang||unseal#} operator can be used to effectively un-seal a previously-sealed symbol. Use with caution!


{#link-learn||control-flow||Control Flow#}
