{@ _defs_.md || 0 @}

{#op||ask||{{s1}}||{{s2}}||
Prints {{s1}} (prompt), reads a line from STDIN and places it on top of the stack as a string.#}

{#op||choose||(({{s1}} {{q1}}){{1p}}) {{s2}}||{{a0p}}||
> Prints {{s2}}, then prints all {{s1}} included in the quotation prepended with a number, and waits from valid input from the user.
> 
> If the user enters a number that matches one of the choices, then the corresponding quotation {{q1}} is executed, otherwise the choice menu is displayed again until a valid choice is made. #}
 
{#op||column-print||{{q}} {{i}}||{{any}}||
Prints all elements of {{q}} to STDOUT, in {{i}} columns.#}

{#op||confirm||{{s}}||{{b}}||
> Prints {{s}} (prompt) appending `" [yes/no]: "`, reads a line from STDIN and:
> 
>  * if it matches `/^y(es)$/i`, puts {{t}} on the stack.
>  * if it matches `/^no?$/i`, puts {{f}} on the stack. 
>  * Otherwise, it prints `Invalid answer. Please enter 'yes' or 'no': ` and waits for a new answer. #}

{#op||debug||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [debug](class:kwd) or lower.#}

{#op||error||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, if logging level is set to [error](class:kwd) or lower.#}

{#op||fappend||{{s1}} {{s2}}||{{null}}||
Appends {{s1}} to the end of file {{s2}}. #} 

{#op||fatal||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, and exists the program with error code `100`.#}

{#op||fread||{{s}}||{{s}}||
Reads the file {{s}} and puts its contents on the top of the stack as a string.#}

{#op||fwrite||{{s1}} {{s2}}||{{null}}||
Writes {{s1}} to the file {{s2}}, erasing all its contents first. #}

{#op||gets||{{null}}||{{s}}||
Reads a line from STDIN and places it on top of the stack as a string.#}

{#op||info||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [info](class:kwd) or lower.#}

{#op||newline||{{null}}||{{null}}||
Prints a new line to STDOUT.#}

{#op||notice||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT, if logging level is set to [notice](class:kwd) (default) or lower.#}

{#op||password||{{null}}||{{s}}||
Reads a line from STDIN displaying \* for each typed character, and places it on top of the stack as a string.#}

{#op||print||{{any}}||{{any}}||
Prints {{any}} to STDOUT.#}

{#op||print!||{{any}}||{{null}}||
Prints {{any}} to STDOUT and removes {{any}} from the stack.#}

{#op||puts||{{any}}||{{any}}||
Prints {{any}} and a new line to STDOUT.#}

{#op||puts!||{{any}}||{{null}}||
Prints {{any}} and a new line to STDOUT, removing {{any}} from the stack.#}

{#op||warning||{{any}}||{{any}}||
Prints {{any}} and a new line to STDERR, if logging level is set to [warning](class:kwd) or lower.#}

