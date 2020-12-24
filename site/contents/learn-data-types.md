-----
content-type: "page"
title: "Learn: Data Types"
-----
{@ _defs_.md || 0 @}


The type system of min is very simple -- only the following data types are available:

null
: null value.
boolean
: **true** or **false**.
integer
: A 64-bit integer number like 1, 27, or -15.
float
: A 64-bit floating-point number like 3.14 or -56.9876.
string
: A series of characters wrapped in double quotes: "Hello, World!".
quotation
: A list of elements, which may also contain symbols. Quotations can be used to create heterogenous lists of elements of any data type, and also to create a block of code that will be evaluated later on (quoted program). Example: (1 2 3 + \*)
dictionary
: A key/value table. Dictionaries are implemented as an immediately-dequoted quotation, are enclosed in curly braces, and are represented by their symbol definitions. Note that dictionary keys must start with `:`and be followed by a double-quoted string, or a single word (which can be written witbout double quotes). The {#link-module||dict#} provides some operators on dictionaries.

  > %sidebar%
  > Example
  >
  > The following is a simple dictionary containing three keys: *name*, *paradigm*, and *first-release-year*:
  >
  >     {
  >         "min" :name
  >         "concatenative" :paradigm
  >         2017 :"first release year"
  >     }

The {#link-module||logic#} provides predicate operators to check if an element belongs to a particular data type or pseudo-type (`boolean?`, `number?`, `integer?`, `float?`, `string?`, `quotation?`, `dictionary?`).

Additionally, the {#link-module||lang#} provides operators to convert values from a data type to another (e.g. {#link-operator||lang||int#}, {#link-operator||lang||string#}, and so on).

> %note%
> Note
> 
> Most of the operators defined in the {#link-module||num#} are able to operate on both integers and floats.

{#link-learn||operators||Operators#}
