{@ _defs_.md || 0 @}

{#op||bind||\* §||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl}}.#}

{#op||call||(\*) §||\*?||
Calls operator {{sl}} defined in scope {{q}}. #}

{#op||debug||{{null}}||{{null}}||
Toggles debug mode. #}

{#op||debug?||{{null}}||B||
Returns {{t}} if debug mode is on, {{f}} otherwise. #}

{#op||define||\* §||{{null}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted).#}

{#op||delete||§||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||eval||S||\*?||
Parses and interprets {{s}}. #}

{#op||exit||{{null}}||{{null}}||
Exits the program or shell. #}

{#op||format-error||(E)||S||
Formats the error {{e}} as a string.

> %sidebar%
> Example
> 
> The following: 
> 
> `((error "MyError") (message "This is a test error")) format-error`
> 
> produces: `"This is a test error"`#}

{#op||from-json||S||\*||
Converts a JSON string into {{M -> min}} data.#}

{#op||import||§||{{null}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||inspect||(\*)||(S+)||
Returns a list of symbols published on {{q}}'s scope. #}

{#op||load||S||\*?||
Parses and interprets the specified {{M}} file {{s}}, adding [.min](class:ext) if not specified. #}

{#op||loglevel||§||{{null}}||
Sets the current logging level to {{sl}}. {{sl}} must be one of the following strings or quoted symbols:

  * debug
  * info
  * notice
  * warn
  * error
  * fatal

> %note%
> Note
> 
> The default logging level is _notice_.
 #}

{#op||module||(\*) §||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||publish||§ (*)||{{null}}||
Publishes symbol {{sl}} to the scope of [(\*)](class:kwd).
> 
> > %sidebar%
> > Example
> >
> Publish symbol [my-local-symbol](class:kwd) to [ROOT](class:kwd) scope:
> > `'my-local-symbol ROOT publish` #}

{#op||raise||(E)||{{null}}||
Raises the error specified via the dictionary {{e}}.#}

{#op||sigils||{{null}}||(S+)||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||§||(\*)||
Display the source code of symbol {{sl}} (if it has been implemented a {{M}} quotation). #}

{#op||symbols||{{null}}||(S+)||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

{#op||to-json||(\*)||S||
Converts a quotation into a JSON string {{s}}.#}


{#op||try||(\*)||\*?||
Evaluates quotation {{q}} as a try/catch/finally block. 
> 
> {{q}} must contain the following elements:
> 
> 1. A quotation containing the code to be evaluated (_try_ block).
> 1. _(optional)_ A quotation containing the code to execute in case of error (_catch_ block).
> 1. _(optional)_ A quotation containing the code to execute after the code has been evaluated, whether an error occurred or not (_finally_ block).
> 
>> %sidebar%
>> Example
>>
>> The following program executed on an empty stack prints the message "Insufficient items on the stack" and pushes 0 on the stack:
>> 
>>       (
>>         (pop)
>>         (format-error puts)
>>         (0)
>>       ) try #}

{#op||with||(2) (1)||\*?||
Applies quotation {{2}} within the scope of {{1}}. #}

