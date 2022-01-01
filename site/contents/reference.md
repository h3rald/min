-----
content-type: "page"
title: "Reference"
-----
{@ _defs_.md || 0 @}

min includes a small but powerful standard library organized into the following _modules_:

{#link-module||lang#}
: Defines the basic language constructs, such as control flow, type conversions, symbol definition and binding, exception handling,  etc.
{#link-module||stack#}
: Defines combinators and stack-shufflers like dip, dup, swap, cons, etc.
{#link-module||seq#}
: Defines operators for quotations, like map, filter, reduce, etc.
{#link-module||dict#}
: Defines operators for dictionaries, like dget, ddup, dset, etc.
{#link-module||dstore#}
: Provides support for simple, persistent, in-memory JSON stores.
{#link-module||io#}
: Provides operators for reading and writing files as well as printing to STDOUT and reading from STDIN.
{#link-module||fs#}
: Provides operators for accessing file information and properties. 
{#link-module||logic#}
: Provides comparison operators for all min data types and other boolean logic operators.
{#link-module||str#}
: Provides operators to perform operations on strings, use regular expressions, interpolation, etc..
{#link-module||sys#}
: Provides operators to use as basic shell commands, access environment variables, and execute external commands.
{#link-module||num#}
: Provides operators to perform simple mathematical operations on integer and floating point numbers.
{#link-module||time#}
: Provides a few basic operators to manage dates, times, and timestamps.
{#link-module||crypto#}
: Provides operators to compute hashes (MD4, MD5, SHA1, SHA224, SHA256, SHA384, sha512), base64 encoding/decoding, and AES encryption/decryption.
{#link-module||math#}
: Provides many mathematical operators and constants such as trigonometric functions, square root, logarithms, etc.
{#link-module||net#}
: Provides basic supports for sockets (some features are not supported on Windows systems).
{#link-module||http#}
: Provides operators to perform HTTP requests, download files and create basic HTTP servers.


## Notation

The following notation is used in the signature of all min operators:

### Types and Values

{{none}}
: No value.
{{null}}
: null value
{{any}}
: A value of any type.
{{b}}
: A boolean value
{{i}}
: An integer value.
{{flt}}
: A float value.
{{n}}
: A numeric (integer or float) value.
{{s}}
: A string value.
{{sl}}
: A string-like value (string or quoted symbol).
{{q}}
: A quotation (also expressed as parenthesis enclosing other values).
{{d}}
: A dictionary value.
{{help}}
: A help dictionary:

      {
       "puts" :name
       "symbol" :kind
       "a ==>" :signature
       "Prints a and a new line to STDOUT." :description
       ;help
      }
{{url}}
: An URL dictionary:

      {
       "http" :scheme
       "h3rald" :hostname
       "" :port
       "" :username
       "" :password
       "/min" :path
       "" :anchor
       "" :query
       ;url
      }
{{tinfo}}
: A timeinfo dictionary:

      {
       2017 :year
       7 :month
       8 :day
       6 :weekday
       188 :yearday
       15 :hour
       16 :minute
       25 :second
       true :dst
       -3600 :timezone
       ;timeinfo
      }
{{e}}
: An error dictionary:

      {
       "MyError" :error
       "An error occurred" :message
       "symbol1" :symbol
       "dir1/file1.min" :filename
       3 :line
       13 :column
       ;error
      }
{{sock}}
: A socket dictionary that must be created through the {#link-operator||net||socket#} operator:

      {
       "ipv4" :domain
       "stream" :type
       "tcp" :protocol
       ;socket
      }
{{rawval}}
: A raw value dictionary obtained via the {#link-operator||seq||get-raw#} or {#link-operator||dict||dget-raw#} operators:

      {
       "sym" :type
       "my-symbol" :str
       my-symbol :val
       ;rawval
      }
{{dstore}}
: A datastore dictionary that must be created through the {#link-operator||dstore||dsinit#} or {#link-operator||dstore||dsread#} operator:

      {
       {} :data
       "path/to/file.json" :path
       ;datastore
      }
{{req}}
: A request dictionary, representing an HTTP request to be performed through the operators exposed by the {#link-module||http#}:

      {
       "http://httpbin.org/put" :url
       "PUT" :method
       "1.1" :version         ;optional
       "h3rald.com" :hostname ;optional
       {                      
        "it-id" :Accept-Language
        "httpbin.org" :Host
       } :headers             ;optional
       "test body" :body      ;optional
      }
{{res}}
: A response dictionary, representing an HTTP response returned by some of the operators exposed by the {#link-module||http#}:

      {
        "1.1" :version ;optional
        200 :status    ;optional
        {
          "application/json" :Content-Type
        } :headers     ;optional
        "{\"test\": \"This is a test\"}" :body
      }

### Suffixes

The following suffixes can be placed at the end of a value or type to indicate ordering or quantities.

{{1}}
: The first value of the specified type.
{{2}}
: The second value of the specified type.
{{3}}
: The third value of the specified type.
{{4}}
: The fourth value of the specified type.
{{01}}
: Zero or one.
{{0p}}
: Zero or more.
{{1p}}
: One or more
