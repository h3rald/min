-----
content-type: "page"
title: "Learn: Definitions"
-----
{@ _defs_.md || 0 @}


Being a concatenative language, min does not really need named parameters or variables: symbols just pop elements off the main stack in order, and that's normally enough. There is however one small problem with the traditional concatenative paradigm; consider the following program for example:

     dup dup 
     "\.zip$" match 
     swap fsize 1000000 > and 
     swap mtime now 3600 - >

This program takes a single string corresponding to a file path and returns true if it's a .zip file bigger than 1MB that was modified in the last hour. Sure, it is remarkable that no variables are needed for such a program, but it is not very readable: because no variables are used, it is often necessary to make copies of elements and push them to the end of the stack -- that's what the {#link-operator||stack||dup#} and {#link-operator||stack||swap#} are used for.

The good news is that you can use the {#link-operator||lang||define#} operator and the `:` sigil to define new symbols, and symbols can also be set to literals of course.

Consider the following program:

     :filepath
     filepath "\.zip$" match
     filepath fsize 1000000 >
     filepath mtime now 3600 - >
     and and

In this case, the `filepath` symbol is defined and then used on the following three lines, each of which defines a condition to be evaluated. The last line contains just two {#link-operator||logic||and#} symbols necessary to compare the three conditions.


## Lexical scoping and binding

min, like many other programming languages, uses [lexical scoping](https://en.wikipedia.org/wiki/Scope_\(computer_science\)#Lexical_scope_vs._dynamic_scope) to resolve symbols.

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

Simple: `4`. Every quotation defines its own scope, and in each scope, a new variable called `a` is defined. In the innermost scope containing the quotation `(a dup * :a)` the value of `a` is set to `64`, but this value is not propagated to the outer scopes. Note also that the value of `a` in the innermost scope is first retrieved from the outer scope (8).

If we want to change the value of the original `a` symbol defined in the outermost scope, we have to use the {#link-operator||lang||bind#} or its shorthand sigil `@`, so that the program becomes the following:

     4 :a ;First definition of the symbol a
     (
       a 3 + @a ;The value of a is updated to 7.
       (
         a 1 + @a ;The value of a is updated to 8
         (a dup * @a) dequote ;The value of a is now 64
       ) dequote
     ) dequote

## Sealing symbols

Finally, symbols can be sealed to prevent accidental updates or deletions. By default, all symbols defined in the core min modules are sealed, so the following code if run in min shell will result in an error:

     5 :quote

...because the symbol quote is already defined in the root scope. However, note that the following code will _not_ return an error:

     (5 :quote quote dup *) -> ;returns 25

...because the `quote` symbol is only defined in the root scope and can therefore be redefined in child scopes.

If you want, you can {#link-operator||lang||seal#} your own symbols so that they may not be redefined using the {#link-operator||lang||bind#} operator or deleted using the {#link-operator||lang||delete#}.

> %note%
> Note
> 
> The {#link-operator||lang||unseal-symbol#} operator can be used to effectively un-seal a previously-sealed symbol. Use with caution!


{#link-learn||scopes||Scopes#}
