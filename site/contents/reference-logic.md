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

{#op||dequote-and||{{a1}} {{a2}}||{{b}}||
> Short-circuited logical and. It performs the following operations:
> 
> 1. Pops {{a1}} and {{a2}} off the stack.
> 2. Dequotes {{a1}}, if {{f}} is on the stack, it pushes {{f}} on the stack and stops, otherwise it carries on.
> 3. Dequotes {{a2}}.
> 4. If {{a2}} is {{t}}, it pushes {{t}} on the stack.
> 
> > %note%
> > Note
> > 
> > {{a1}} (and {{a2}}, if dequoted) must evaluate to a boolean value, otherwise an exception is raised.
> 
> > %sidebar%
> > Example
> > 
> > The following program returns {{f}} and never executes the second quotation.
> > 
> >      "test" :x (x number?) (x 5 <) dequote-and

 #}

{#op||dequote-or||{{a1}} {{a2}}||{{b}}||
> Short-circuited logical or. It performs the following operations:
> 
> 1. Pops {{a1}} and {{a2}} off the stack.
> 2. Dequotes {{a1}}, if {{t}} is on the stack, it pushes {{t}} on the stack and stops, otherwise it carries on.
> 3. Dequotes {{a2}}.
> 4. If {{a2}} is {{f}}, it pushes {{f}} on the stack.
> 
> > %note%
> > Note
> > 
> > {{a1}} (and {{a2}}, if dequoted) must evaluate to a boolean value, otherwise an exception is raised.
> 
> > %sidebar%
> > Example
> > 
> > The following program returns {{t}} and never executes the second quotation.
> > 
> >      "test" :x (x string?) (x quotation?) dequote-or
 #}

{#op||dictionary?||{{any}}||{{b}}||
Returns {{t}} if {{any}} is a dictionary, {{f}} otherwise. #}

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

{#op||type?||{{any}} {{sl}}||{{b}}||
Returns {{t}} if the data type of {{any}} is the specified type {{sl}}, {{f}} otherwise. #}

{#op||xor||{{b1}} {{b2}}||{{b3}}||
Returns {{t}} if {{b1}} and {{b2}} are different, {{f}} otherwise.#}

