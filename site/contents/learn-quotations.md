-----
content-type: "page"
title: "Learn: Quotations"
-----
{@ _defs_.md || 0 @}

Quotations are the most important thing to understand in min. Besides being the data type used for lists, they are also used to delimit blocks of min code that is not going to be immediately executed. 

Consider for example the following min code which returns all the files present in the current folder sorted by name:

     . ls (ftype "file" ==) filter '> sort

The symbol {#link-operator||seq||filter#} takes two quotations as arguments -- the first quotation on the stack is applied to all the elements of the second quotation on the stack, to determine which elements of the second quotation will be part of the resulting quotation. This is an example of how quotations can be used both as lists and programs.

Let's examine this program step-by-step:

{{fdlist => ("dir1" "dir2" file1.txt "file2.txt" "file3.md" "file4.md")}}
{{flist => ("file1.txt" "file2.txt" "file3.md" "file4.md")}}

1. The `.` symbol is pushed on the stack, and it is immediately evaluated to the full path to the current directory.
2. The `ls` symbol is pushed on the stack, it consumes the string already on the stack and returns a quotation containing all files and directories within the current directory. 
3. The quotation `(ftype 'file ==)` is pushed on the stack. It is treated exactly like a list of data and it is not evaluated.
4. The `filter` symbol is pushed on the stack. This symbol takes two quotations as input, and applies the result of the first quotation on the stack (`(ftype "file" ==)`) to all elements of the second quotation of the stack (the list of files and directories), returning a new quotation containing only those elements of the second quotation on the stack that satisfy the result of the first quotation. In this case, it returns a new quotation containing only files.
5. `'>` is pushed on the stack. The `'` sigil can be used instead of the `quote` symbol to quote a single symbol, `<` in this case. In other words, it is instantly evaluated to the quotation `(>)`.
6. The symbol `sort` is pushed on the stack. This symbol, like `filter`, takes two quotations as input, and applies the first quotation to each element of the second quotation, effectively sorting each element of the second quotation using the predicate expressed by the first quotation. In this case, all files are sorted by name in ascending order.

> %tip%
> Tip
> 
> The {#link-module||seq#} provides several symbols to work with quotations in a functional way.


## Quoting, dequoting, and applying

When a quotation is created, it is treated as data, no matter what it contains: it is placed on the stack, like an integer or a string would. However, unlike other data types, a quotation can be evaluated in certain situations and when it happens its contents are pushed on the stack.

Consider the following program:

     (1 2 3 4 5 6 7) (odd?) filter

This programs returns a new quotation containing all odd numbers contained in quotation `(1 2 3 4 5 6 7)`.

In this case, the second quotation is used to _quote_ the symbol `odd?` so that instead of being executed immediately, it will be executed by the symbol `filter` on each element of the first quotation. In this way, we may say that `(odd?)` is _dequoted_ by the symbol `filter`.

The synbol {#link-operator||lang||dequote#} or its alias `->` can be used to dequote a quotation by pushing all its element on the main stack, while the symbol {#link-operator||lang||apply#} can be used to dequote a quotation by pushing its element on a separate stack.

{#link-learn||definitions||Definitions#}
