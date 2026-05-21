-----
content-type: "page"
title: "Learn: Data Types"
-----
{@ _defs_.md || 0 @}


The following data types are availanle in {{m}} (with the corresponding shorthand symbols used in operator signatures in brackets):

null (null)
: null value.
boolean (bool)
: **true** or **false**.
integer (int)
: A 64-bit integer number like 1, 27, or -15.
float (flt)
: A 64-bit floating-point number like 3.14 or -56.9876.
string (str)
: A series of characters wrapped in double quotes: "Hello, World!".
quotation (quot)
: A list of elements, which may also contain symbols. Quotations can be used to create heterogenous lists of elements of any data type, and also to create a block of code that will be evaluated later on (quoted program). Example: (1 2 3 + \*)
command (cmd)
: A command string wrapped in square brackets that will be immediately executed on the current shell and converted into the command standard output. Example: `[ls -a]`
dictionary (dict)
: A key/value table. Dictionaries are implemented as an immediately-dequoted quotation, are enclosed in curly braces, and are represented by their symbol definitions. Note that dictionary keys must start with `:` or `^` and be followed by a double-quoted string, or a single word (which can be written without double quotes). The {#link-module||dict#} provides some operators on dictionaries.

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

Theere are two types of dictionary keys:
* _define keys_, which are prepended by `:`, which are used to store data, including quotations that will be interpreted as lists of values. 
* _lambda keys_, which are prepended by `^`, which are used to store executable code. In this case, a quotation will be immediately executed when accessed.

> %sidebar%
> Example
> 
> The following program prints `16`:
>
>     ; First, define a dictionary with a value using a define key
>     ; and an operation using a lambda key
>     {4 :value (dup *) ^square} :test
>     ; When accessing the quotation, it will be executed immediately
>     test.value test.square puts 

Additionally, dictionaries can also be typed to denote complex objects like sockets, errors, etc. For example, the following dictionary defines an error:

      {
       "MyError" :error
       "An error occurred" :message
       "symbol1" :symbol
       "dir1/file1.min" :filename
       3 :line
       13 :column
       ;error
      }

> %tip%
> Tip
> 
> The {#link-operator||dict||dtype#} operator can be used to set the type of a dictionary.

The {#link-module||global#} provides predicate operators to check if an element belongs to a particular data type or pseudo-type (`boolean?`, `number?`, `integer?`, `float?`, ...).

Additionally, the {#link-module||global#} provides operators to convert values from a data type to another (e.g. {#link-global-operator||integer#}, {#link-global-operator||string#}, and so on).

{#link-learn||operators||Operators#}
