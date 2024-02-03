-----
content-type: "page"
title: "Get Started"
-----
{@ _defs_.md || 0 @}


You can download one of the following pre-built min binaries:

* {#release||{{$version}}||macosx||macOS||x64#}
* {#release||{{$version}}||windows||Windows||x64#}
* {#release||{{$version}}||linux||Linux||x64#}

{#release -> [min v$1 for $3 ($4)](https://github.com/h3rald/min/releases/download/v$1/min\_v$1\_$2\_$4.zip) #}

{{guide-download}}

## Building from source

Alternatively, you can build min from source in one of the following ways:

### Using nimble

If you already installed [nim](https://nim-lang.org), you probably already have the [nimble](https://github.com/nim-lang/nimble) package manager installed.

If that's the case, simply run **nimble install min**. 

### Building from source for additional platforms

By default, min is released as a pre-built binary executable for Windows x64, macOS x64 and Linux x64. However, it should run without issues on any [platform supported by the Nim programming language](https://github.com/nim-lang/Nim/blob/devel/lib/system/platforms.nim).

To build on a different operating system and architecture from the default ones, you also need to get or build the following static libraries:

* libssl (OpenSSL)
* libcrypto (OpenSSL)
* libpcre (PCRE)

and also specify the following additional flag when compiling:

`--passL:"-static -L<dir> -lpcre -lssl -lcrypto"`

Where `<dir>` is the directory containing the `*.a` files for the static libraries listed above.

> %tip%
> 
> Alternatively, if you can also opt out from OpenSSL and PCRE support by:
>
> * Specifying `-d:nossl`
> * Specifying `-d:nopcre`

### Additional build options

#### -d:ssl

If the **-d:ssl** flag is specified when compiling, min will be built with SSL support, so it will be possible to:

* perform HTTPS requests with the {#link-module||http#}.
* use all the cryptographic symbols defined in the {#link-module||crypto#}.

If this flag is not specified:

* It will not be possible to perform HTTPS requests
* Only the following symbols will be exposed by the {#link-module||crypto#}:

  * {#link-operator||crypto||md5#} 
  * {#link-operator||crypto||sha1#} 
  * {#link-operator||crypto||encode#} 
  * {#link-operator||crypto||decode#} 
  * {#link-operator||crypto||aes#} 

#### -d:nopcre

If the **-d:nopcre** is specified when compiling, min will be built _without_ PCRE support, so it will not be possible to use regular expressions and the following symbols will _not_ be exposed by the {#link-module||str#}:

* {#link-operator||str||search#}
* {#link-operator||str||match?#}
* {#link-operator||str||search-all#}
* {#link-operator||str||replace#}
* {#link-operator||str||replace-apply#}

## Building a docker image

[Yanis Zafirópulos](https://github.com/drkameleon) contributed a Dockerfile that you can use to create your own Docker image for min based on Alpine Linux.

To build the image locally, execute the following command from the repository root directory:

> %terminal%
> docker build \-t mindocker .

To run it, execute:

> %terminal%
> docker run \-it mindocker

## Running the min shell

To start the min shell, run [min](class:cmd) with no arguments. You will be presented with a prompt displaying the path to the current directory:

> %min-terminal%
> min shell v{{$version}}
> [[/Users/h3rald/test]$](class:prompt)

You can type min code and press [ENTER](class:kbd) to evaluate it immediately:

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt) 2 2 +
>  4 
> [[/Users/h3rald/test]$](class:prompt)

The result of each operation will be placed on top of the stack, and it will be available to subsequent operation

> %min-terminal%
> [[/Users/h3rald/test]$](class:prompt) dup *
>  16
> [[/Users/h3rald/test]$](class:prompt)

To exit min shell, press [CTRL+C](class:kbd) or type [0 exit](class:cmd) and press [ENTER](class:kbd).

> %tip%
> Tip
> 
> By default, the min shell provides advanced features like tab-completion, history, etc. If however, you run into problems, you can disable these features by running [min -j](class:cmd) instead, and run min shell with a bare-bones REPL. 

## Executing a min program

To execute a min script, you can:

* Run `min eval "... program..."` to execute a program inline.
* Run `min myfile.min` to execute a program contained in a file.
* Run `min run <mmm>` to execute the `main` symbol of the specified [min managed module](/learn-mmm/). If the managed module is not installed globally, it will be downloaded and installed automatically.

min also supports running programs from standard input, so the following command can also be used (on Unix-like system) to run a program saved in [myfile.min](class:file):

> %min-terminal%
> 
> [$](class:prompt) cat myfile.min | min

> %tip%
> 
> You can enable _development mode_ (runtime checks and validations) by specifying `-d` (`--dev`) when running a min program. If development mode is not enabled, min programs run faster.

## Compiling a min program

min programs can be compiled to a single executable simply by using the built-in `compile` command:

> %min-terminal%
> 
> [$](class:prompt) min compile myfile.min

Essentially, this will:

1. Generate a [myfile.nim](class:file) containing the equivalent Nim code of your min program.
2. Call the Nim compiler to do the rest ;)

If you want to pass any options to the Nim compiler (like `-d:release` for example) you can do so by using the `-n` (or `--passN`) option:

> %min-terminal%
> 
> [$](class:prompt) min compile myfile.min -n:&quot;-d:release --threadAnalysis:off --mm:refc&quot;

Additionally, you can also use `-m:<path>` (or `--module-path`) to specify one path containing [.min](class:ext) files which will be compiled as well (but not executed) along with the specified file. Whenever a {#link-operator||global||load#} or a {#link-operator||global||require#} symbol is used to load/require an external [.min](class:ext) file, it will attempt to retrieve its contents from the pre-loaded files first before searching the filesystem.

For example, the following command executed in the root folder of the min project will compile [run.min](class:file) along with all [.min](class:ext) files included in the [tasks](class:dir)  folder and its subfolders:

> %min-terminal%
> 
> [$](class:prompt) min compile run.min -m:tasks

Similarly, you can also bundle additional files in the executable by specifying the `-a:<path>` (or `--asset-path`) option. At runtime, the compiled min program will attempt to lookup bundled asset files before checking the filesystem.

> %note%
> Note
> 
> In order to successfully compile [.min](class.ext) files, Nim must be installed on your system and min must be installed via nimble.

## Getting help on a min symbol

min comes with a built-in `help` command that can be used to print information on a specific symbol. Essentially, this is equivalent to use the {#link-operator||global||help#} symbol within the min REPL.

> %min-terminal%
> 
> [$](class:prompt) min help dup

## Syntax highlighting

* If you are using [Visual Studio Code](https://code.visualstudio.com/), you can install the official [min extension](https://marketplace.visualstudio.com/items?itemName=h3rald.vscode-min-lang) which provides syntax highlighting support, code folding, and auto-indentation.
* If you are using [Vim](https://www.vim.org), a [min.vim](https://github.com/h3rald/min/blob/master/min.vim) syntax definition file is available in the min repo.
* If you are using [Sublime Text 3](https://www.sublimetext.com/3), Rafael Carrasco created a min syntax definition file that is available [here](https://github.com/rscarrasco/min-sublime-syntax).
* If you are using [Notepad++](https://notepad-plus-plus.org), a [Notepad++ language file](https://github.com/h3rald/min/blob/master/minNotepad++.xml) contributed by baykus871 is available in the repo.
