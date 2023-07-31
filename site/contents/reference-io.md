-----
content-type: "page"
title: "io Module"
-----
{@ _defs_.md || 0 @}

{#op||ask||{{s1}}||{{s2}}||
Prints {{s1}} (prompt), reads a line from STDIN and places it on top of the stack as a string.#}

{#op||choose||(({{s1}} {{q1}}){{1p}}) {{s2}}||{{a0p}}||
> Prints {{s2}}, then prints all {{s1}} included in the quotation prepended with a number, and waits from valid input from the user.
> 
> If the user enters a number that matches one of the choices, then the corresponding quotation {{q1}} is executed, otherwise the choice menu is displayed again until a valid choice is made. #}

{#op||clear||{{none}}||{{none}}||
Clears the screen.#}
 
{#op||column-print||{{q}} {{i}}||{{any}}||
Prints all elements of {{q}} to STDOUT, in {{i}} columns.#}

{#op||confirm||{{s}}||{{b}}||
> Prints {{s}} (prompt) appending `" [yes/no]: "`, reads a line from STDIN and:
> 
>  * if it matches `/^y(es)?$/i`, puts {{t}} on the stack.
>  * if it matches `/^no?$/i`, puts {{f}} on the stack. 
>  * Otherwise, it prints `Invalid answer. Please enter 'yes' or 'no': ` and waits for a new answer. #}

{#op||debug||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [debug](class:kwd) or lower.#}

{#op||error||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, if logging level is set to [error](class:kwd) or lower.#}

{#op||fappend||{{s1}} {{s2}}||{{none}}||
Appends {{s1}} to the end of file {{s2}}. #} 

{#op||fatal||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, and exists the program with error code `100`.#}

{#op||fread||{{s}}||{{s}}||
Reads the file {{s}} and puts its contents on the top of the stack as a string.#}

{#op||fwrite||{{s1}} {{s2}}||{{none}}||
Writes {{s1}} to the file {{s2}}, erasing all its contents first. #}

{#op||getchr||{{none}}||{{i}}||
Reads single character from STDIN without waiting for ENTER key and places its ASCII code on top of the stack.#}

{#op||info||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [info](class:kwd) or lower.#}

{#op||mapkey||{{q}} {{sl}}||{{none}}||
> Maps the named key/key combination {{sl}} to the quotation {{q}}, so that {{q}} is executed when key {{sl}} is pressed. 
>
> > %note%
> > Notes
> >
> > * At present, only the key names and sequences defined in the [minline](https://h3rald.com/minline/minline.html) library are supported.
> > * The quotation will be executed by a copy of the min interpreter created when the mapping was defined. In other words, quotations executed by key bindings will not affect the current stack.
> 
> > %sidebar%
> > Example
> > 
> > The following program:
> > 
> >     (clear) 'ctrl+l mapkey 
> > 
> > causes the `CTRL+L` key to clear the screen. #}

{#op||newline||{{none}}||{{none}}||
Prints a new line to STDOUT.#}

{#op||notice||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [notice](class:kwd) (default) or lower.#}

{#op||password||{{none}}||{{s}}||
Reads a line from STDIN displaying \* for each typed character, and places it on top of the stack as a string.#}

{#op||print||{{any}}||{{any}}||
Prints {{any}} to STDOUT.#}

{#op||putchr||{{s}}||{{any}}||
Prints {{s}} to STDOUT without printing a new line ({{s}} must contain only one character).#}

{#alias||read||fread#}

{#op||type||{{any}}||{{s}}||
Puts the data type of {{any}} on the stack. In cased of typed dictionaries, the type name is prefixed by `dict:`, e.g. `dict:module`, `dict:socket`, etc.#}

{#op||unmapkey||{{sl}}||{{none}}||
> Unmaps a previously-mapped key or key-combination {{sl}}, restoring the default mapping if available.
>
> > %note%
> > Notes
> >
> > * At present, only the key names and sequences defined in the [minline](https://h3rald.com/minline/minline.html) library are supported.
> > * At present, all the default mappings of min are those provided by the [minline](https://h3rald.com/minline/minline.html) library.
 #}

{#op||warn||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, if logging level is set to [warn](class:kwd) or lower.#}

{#alias||write||fwrite#}
