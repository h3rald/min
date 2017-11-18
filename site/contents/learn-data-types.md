-----
content-type: "page"
title: "Learn: Data Types"
-----
{@ _defs_.md || 0 @}


The type system of min is very simple -- only the following data types are available:

integer
: An integer number like 1, 27 or -15.
float
: A floating-point number like 3.14 or -56.9876.
string
: A series of characters wrapped in double quotes: "Hello, World!".
quotation
: A list of elements, which may also contain symbols. Quotations can be be used to create heterogenous lists of elements of any data type, and also to create a block of code that will be evaluated later on (quoted program).

Additionally, quotations structured in a particular way can be used as dictionaries, and a few operators are available to manage them more easily (`dhas?`, `dget`, `ddel` and `dset`). A dictionary is a quotation containing zero or more quotations of two elements, the first of which is a symbol that has not already be used in any of the other inner quotations.

> %sidebar%
> Example
>
> The following is a simple dictionary containing three keys: *name*, *paradigm*, and *first-release-year*:
>
>     (
>         ("name" "min")
>         ("paradigm" "concatenative")
>         ("first-release-year" 2017)
>     )

The {#link-module||logic#} provides predicate operators to check if an element belong to a particular data type or pseudo-type (`boolean?`, `number?`, `integer?`, `float?`, `string?`, `quotation?`, `dictionary?`).

> %note%
> Note
> 
> Most of the operators defined in the {#link-module||num#} are able to operate on both integers and floats.

{#link-learn||operators||Operators#}
