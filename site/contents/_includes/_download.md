{@ _defs_.md || 0 @}

You can download one of the following pre-built min binaries:

* {#release||{{$version}}||macosx||macOS||x64#}
* {#release||{{$version}}||windows||Windows||x64#}
* {#release||{{$version}}||linux||Linux||x64#}
* {#release||{{$version}}||linux||Linux||x86#}
* {#release||{{$version}}||linux||Linux||arm#}

{#release -> [min v$1 for $3 ($4)](https://github.com/h3rald/min/releases/download/v$1/min\_v$1\_$2\_$4.zip) #}

{{guide-download}}

## Building from Source

Alternatively, you can build min from source as follows:

1. Download and install [nim](https://nim-lang.org).
2. Download and build [Nifty](https://github.com/h3rald/nifty), and put the nifty executable somewhere in your [$PATH](class:kwd).
3. Clone the min [repository](https://github.com/h3rald/min).
4. Navigate to the min repository local folder.
5. Run **nifty install** to download min’s dependencies.
7. Run **nim c -d:release min.nim**.

## Running then min Shell

To start min shell, run [min -i](class:cmd). You will be presented with a prompt displaying the path to the current directory:

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt)

You can type min code and press [ENTER](class:kbd) to evaluate it immediately:

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt) 2 2 +
> {1} -> 4 
> [[/Users/h3rald/test]$](class:prompt)

The result of each operation will be placed on top of the stack, and it will be available to subsequent operation

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt) dup *
> {1} -> 16
> [[/Users/h3rald/test]$](class:prompt)

To exit min shell, press [CTRL+C](class:kbd) or type [exit](class:cmd) and press [ENTER](class:kbd).

## Executing a min Program

To execute a min script, you can:

* Run `min -e:"... program ..."` to execute a program inline.
* Run `min myfile.min` to execute a program contained in a file.

min also supports running programs from standard input, so the following command can also be used (on Unix-like system) to run a program saved in [myfile.min](class:file):

> %min-terminal%
> 
> [$](class:prompt) cat myfile.min | min
