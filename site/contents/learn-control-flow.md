-----
content-type: "page"
title: "Learn: Control Flow"
-----
{@ _defs_.md || 0 @}


The {#link-module||global#} provide some symbols that can be used for the most common control flow statements. Unlike most programming languages, min does not differentiate between functions and statements -- control flow statements are just ordinary symbols that manipulate the main stack.


## Conditionals

The following symbols provide ways to implement common conditional statements:

* {#link-operator||global||case#}
* {#link-operator||global||if#}
* {#link-operator||global||unless#}
* {#link-operator||global||when#}

For example, consider the following program:

     (
       (  
         "" :type
         (("\.(md|markdown)$") ("markdown" @type))
         (("\.txt$") ("text" @type))
         (("\.min$") ("min" @type))
         (("\.html?$") ("HTML" @type))
         ((true) ("unknown" @type))
       ) case 
       "This is a $1 file." (type) % echo
     ) ^display-file-info

This program defines a symbol `display-file-info` that takes a file name and outputs a message displaying its type if known.


## Loops

The following symbols provide ways to implement common loops:

* {#link-operator||global||foreach#}
* {#link-operator||global||times#}
* {#link-operator||global||while#}


For example, consider the following program:

     (
       :n
       1 :i
       1 :f
       (i n <=)
       (
         f i * @f 
         i succ @i
       ) while
       f
     ) ^factorial

This program defines a symbol `factorial` that calculates the factorial of an integer iteratively using the symbol {#link-operator||global||while#}.

## Error handling

The following symbols provide ways to manage errors in min:

* {#link-operator||global||format-error#}
* {#link-operator||global||raise#}
* {#link-operator||global||try#}

For example, consider the following program:

     . ls 
     (
       (
         (fsize) 
         (pop 0)
       ) try
     ) map 
     1 (+) reduce

This program calculates the size in bytes of all files included in the current directory. Because the {#link-operator||fs||fsize#} symbol throws an error if the argument provided is not a file (for example, if it is a directory), the `try` symbol is used to remove the error from the stack and push `0` on the stack instead.

{#link-learn||shell||Shell#}
