-----
content-type: "page"
title: "num Module"
-----
{@ _defs_.md || 0 @}

{#op||+||{{n1}} {{n2}}||{{n3}}||
Sums {{n1}} and {{n2}}. #}

{#op||-||{{n1}} {{n2}}||{{n3}}||
Subtracts {{n2}} from {{n1}}. #}

{#op||-inf||{{none}}||{{n}}||
Returns negative infinity. #}

{#op||&ast;||{{n1}} {{n2}}||{{n3}}||
Multiplies {{n1}} by {{n2}}. #}

{#op||/||{{n1}} {{n2}}||{{n3}}||
Divides {{n1}} by {{n2}}. #}

{#op||avg||{{q}}||{{n}}||
Returns the average of the items of {{q}}. #}

{#op||bitand||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *and* of numbers {{i1}} and {{i2}}.#}

{#op||bitnot||{{i1}}||{{i2}}||
Computes the bitwise *complement* of {{i1}}.#}

{#op||bitor||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *or* of numbers {{i1}} and {{i2}}.#}

{#op||bitxor||{{i1}} {{i2}}||{{i3}}||
Computes the bitwise *xor* of numbers {{i1}} and {{i2}}.#}

{#op||even?||{{i}}||{{b}}||
Returns {{t}} if {{i}} is even, {{f}} otherwise. #}

{#op||div||{{i1}} {{i2}}||{{i3}}||
Divides {{i1}} by {{i2}} (integer division). #}

{#op||inf||{{none}}||{{n}}||
Returns infinity. #}

{#op||med||{{q}}||{{n}}||
Returns the median of the items of {{q}}. #}

{#op||mod||{{i1}} {{i2}}||{{i3}}||
Returns the integer module of {{i1}} divided by {{i2}}. #}

{#op||nan||{{none}}||nan||
Returns **NaN** (not a number). #}

{#op||odd?||{{i}}||{{b}}||
Returns {{t}} if {{i}} is odd, {{f}} otherwise. #}

{#op||pred||{{i1}}||{{i2}}||
Returns the predecessor of {{i1}}.#}

{#op||product||{{q}}||{{i}}||
Returns the product of all items of {{q}}. {{q}} is a quotation of integers. #}

{#op||random||{{i1}}||{{i2}}||
> Returns a random number {{i2}} between 0 and {{i1}}-1. 
> 
> > %note%
> > Note
> > 
> > You must call `randomize` to initialize the random number generator, otherwise the same sequence of numbers will be returned.#}

{#op||randomize||{{none}}||{{null}||
Initializes the random number generator using a seed based on the current timestamp. #}

{#op||range||{{q2}}||{{q2}}||
Takes a quotation {{q1}} of two or three integers in the form of *start*, *end* and an optional *step* (1 if not specified) and generates the sequence and returns the resulting quotation of integers {{q2}}. #}

{#op||shl||{{i1}} {{i2}}||{{i3}}||
Computes the *shift left* operation of {{i1}} and {{i2}}.#}

{#op||shr||{{i1}} {{i2}}||{{i3}}||
Computes the *shift right* operation of {{i1}} and {{i2}}.#}

{#op||succ||{{i1}}||{{i2}}||
Returns the successor of {{i1}}.#}

{#op||sum||{{q}}||{{i}}||
Returns the sum of all items of {{q}}. {{q}} is a quotation of integers. #}

