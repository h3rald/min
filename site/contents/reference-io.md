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

{#op||color||{{b}}||{{none}}||
Enables or disabled color output in terminal (enabled by default).#}
 
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

{#op||fatal||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, and exists the program with error code `100`.#}

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
> >     (clear) 'ctrl+l io.mapkey 
> > 
> > causes the `CTRL+L` key to clear the screen. #}

{#op||notice||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [notice](class:kwd) (default) or lower.#}

{#op||password||{{none}}||{{s}}||
Reads a line from STDIN displaying \* for each typed character, and places it on top of the stack as a string.#}

{#op||print||{{any}}||{{any}}||
Prints {{any}} to STDOUT.#}

{#op||putchr||{{s}}||{{any}}||
Prints {{s}} to STDOUT without printing a new line ({{s}} must contain only one character).#}

{#alias||read||fread#}

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
