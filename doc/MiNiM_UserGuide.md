% MiNiM User Guide
% Fabio Cevasco
% -

## Overview
## Usage
## Reference

{#op -> 
#### $1

_Signature:_ [ $2 **&rArr;** $3](class:kwd)

$4

 #}

### `lang` Module

{#op||bind||\* §||{{null}}||
Binds the specified value (auto-quoted) to an existing symbol {{sl -> [§](class:kwd)}}.#}

{#op||call||(\*) §||\*?||
Calls operator {{sl}} defined in scope [(\*)](class:kwd). #}

{#op||debug||{{null}}||{{null}}||
Toggles debug mode. #}

{#op||debug?||{{null}}||B||
Returns {{t -> [true](class:kwd)}} if debug mode is on, {{f -> [false](class:kwd)}} otherwise. #}

{#op||define||\* §||{{null}}||
Defines a new symbol {{sl}}, containing the specified value (auto-quoted).#}

{#op||delete||§||{{null}}||
Deletes the specified symbol {{sl}}.#}

{#op||eval||S||\*?||
Parses and interprets {{s -> [S](class:kwd)}}. #}

{#op||exit||{{null -> &#x2205;}}||{{null}}||
Exits the program or shell. #}

{#op||from-json||S||\*||
Converts a JSON string into {{M -> MiNiM}} data.#}

{#op||import||§||{{null}}||
Imports the a previously-loaded module {{sl}}, defining all its symbols in the current scope. #}

{#op||load||S||\*?||
Parses and interprets the specified {{M}} file {{s -> [S](class:kwd)}}, adding [.min](class:ext) if not specified. #}

{#op||module||(\*) §||{{null}}||
Creates a new module {{sl}} based on quotation {{q}}. #}

{#op||scope||(\*)||(\*)||
Unquotes {{q -> [(\*)](class:kwd)}} creating a new scope and pushes a new copy of {{q}} on the stack.#}

{#op||scope?||(\*)||(B)||
Returnes {{t}} if {{q}} defines a scope, {{f}} otherwise. #}

{#op||sigils||{{null}}||(S+)||
Returns a list of all sigils defined in the [ROOT](class:kwd) scope.#}

{#op||source||§||(\*)||
Display the source code of symbol {{sl}} (if it has been implemented a {{M}} quotation). #}

{#op||symbols||{{null}}||(S+)||
Returns a list of all symbols defined in the [ROOT](class:kwd) scope.#}

{#op||to-json||(\*)||S||
Converts a quotation into a JSON string {{s}}.#}

{#op||with||(2) (1)||\*?||
Applies quotation [(2)](class:kwd) within the scope of [(1)](class:kwd). #}

### `io` Module

### `fs` Module

### `sys` Module

### `str` Module

### `logic` Module

### `num` Module

### `time` Module

### `crypto` Module
