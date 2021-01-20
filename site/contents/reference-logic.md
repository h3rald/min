-----
content-type: "page"
title: "logic Module"
-----
{@ _defs_.md || 0 @}

{#op||&gt;||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is greater than {{a2}}, {{f}} otherwise. 
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#op||&gt;=||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is greater than or equal to {{a2}}, {{f}} otherwise.
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#op||&lt;||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is smaller than {{a2}}, {{f}} otherwise. 
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#op||&lt;=||{{a1}} {{a2}}||{{b}}||
> Returns {{t}} if {{a1}} is smaller than or equal to {{a2}}, {{f}} otherwise.
> > %note%
> > Note
> > 
> > Only comparisons among two numbers or two strings are supported.#}

{#op||==||{{a1}} {{a2}}||{{b}}||
Returns {{t}} if {{a1}} is equal to {{a2}}, {{f}} otherwise. #}

{#op||!=||{{a1}} {{a2}}||{{b}}||
Returns {{t}} if {{a1}} is not equal to {{a2}}, {{f}} otherwise. #}

{#op||and||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} is equal to {{b2}}, {{f}} otherwise.#}

{#op||boolean?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a boolean, {{f}} otherwise. #}

{#op||dictionary?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a dictionary, {{f}} otherwise. #}

{#op||expect-all||{{q}}||{{b}}||
Assuming that {{q}} is a quotation of quotations each evaluating to a boolean value, it pushes {{t}} on the stack if they all evaluate to {{t}}, {{f}} otherwise.
 #}
 
{#op||expect-any||{{q}}||{{b}}||
Assuming that {{q}} is a quotation of quotations each evaluating to a boolean value, it pushes {{t}} on the stack if any evaluates to {{t}}, {{f}} otherwise.
 #}

{#op||float?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a float, {{f}} otherwise. #}

{#op||or||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} or {{b2}} is {{t}}, {{f}} otherwise.#}

{#op||integer?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is an integer, {{f}} otherwise. #}

{#op||not||{{b1}}||{{b2}}||
Negates {{b1}}.#}

{#op||null?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is {{null}}, {{f}} otherwise. #}

{#op||number?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a number, {{f}} otherwise. #}

{#op||quotation?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a quotation, {{f}} otherwise. #}

{#op||string?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a string, {{f}} otherwise. #}

{#op||stringlike?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a string or a quoted symbol, {{f}} otherwise. #}

{#op||type?||{{any}} {{sl}}||{{b}}||
Returns {{t}} if the data type of {{any}} is the specified type {{sl}}, {{f}} otherwise. #}

{#op||xor||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} and {{b2}} are different, {{f}} otherwise.#}

