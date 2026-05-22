-----
content-type: "page"
title: "Get Started"
-----
{@ _defs_.md || 0 @}

{{guide-download}}

## Installing min

You can install min either by using [Nimble](https://github.com/nim-lang/nimble) or by cloning the [repository](https://github.com/h3rald/min) and building from source.

### Using nimble

If you already installed [Nim](https://nim-lang.org), you probably already have the [Nimble](https://github.com/nim-lang/nimble) package manager installed.

If that's the case, simply run **nimble install min**. 

### Building from source

By default, min should run without issues on any [platform supported by the Nim programming language](https://github.com/nim-lang/Nim/blob/devel/lib/system/platforms.nim).

To build min, you can clone the [git repository](https://github.com/h3rald/min) and also build the following static libraries first:

* libssl (OpenSSL)
* libcrypto (OpenSSL)
* libpcre (PCRE)

When compiling, specify additional flags to specify where to get the static libraries from:

`nim c -d --passL:"-static -L<dir> -lpcre -lssl -lcrypto"`

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

If the **-d:nopcre** is specified when compiling, min will be built _without_ PCRE support, so it will not be possible to use regular expressions and the following symbols will _not_ be exposed by the {#link-module||global#}:

* {#link-global-operator||search#}
* {#link-global-operator||match?#}
* {#link-global-operator||search-all#}
* {#link-global-operator||replace#}
* {#link-global-operator||replace-apply#}

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
> [[/Users/h3rald/test]$](class:prompt) stack.dup *
>  16
> [[/Users/h3rald/test]$](class:prompt)

To exit min shell, press [CTRL+C](class:kbd) or type [0 exit](class:cmd) and press [ENTER](class:kbd).

> %tip%
> Tip
> 
> By default, the min shell provides advanced features like tab-completion, history, etc. If however, you run into problems, you can disable these features by running [min -j](class:cmd) instead, and run min shell with a bare-bones REPL. 

## Executing a min program

To execute a min script, you can:

* Run `min eval "...program..."` to execute a program inline.
* Run `min myfile.min` to execute a program contained in a file.
* Run `min run <mmm>` to execute the `main` symbol of the specified {#link-page||learn-mmm||min managed module#}. If the managed module is not installed globally, it will be downloaded and installed automatically.

min also supports running programs from standard input, so the following command can also be used (on Unix-like system) to run a program saved in [myfile.min](class:file):

> %min-terminal%
> 
> [$](class:prompt) cat myfile.min | min

> %tip%
> Tip
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

Additionally, you can also use `-m:<path>` (or `--module-path`) to specify one path containing [.min](class:ext) files which will be compiled as well (but not executed) along with the specified file. Whenever a {#link-global-operator||load#} or a {#link-global-operator||require#} symbol is used to load/require an external [.min](class:ext) file, it will attempt to retrieve its contents from the pre-loaded files first before searching the filesystem.

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

min comes with a built-in `help` command that can be used to print information on a specific symbol. Essentially, this is equivalent to use the {#link-global-operator||help#} symbol within the min REPL.

> %min-terminal%
> 
> [$](class:prompt) min help stack.dup

## Syntax highlighting

* If you are using [Visual Studio Code](https://code.visualstudio.com/), you can install the official [min extension](https://marketplace.visualstudio.com/items?itemName=h3rald.vscode-min-lang) which provides syntax highlighting support, code folding, and auto-indentation.
* If you are using [Vim](https://www.vim.org), a [min.vim](https://github.com/h3rald/min/blob/master/min.vim) syntax definition file is available in the min repo.
* If you are using [Sublime Text 3](https://www.sublimetext.com/3), Rafael Carrasco created a min syntax definition file that is available [here](https://github.com/rscarrasco/min-sublime-syntax).
