-----
content-type: "page"
title: "Learn: Shell"
-----
{@ _defs_.md || 0 @}

The min executable also provide an interactive REPL (Read-Eval-Print Loop) when launched with the `-i` flag:

> %min-terminal%
> [$](class:prompt) min -i
> <span class="prompt">&#91;/Users/h3rald/Development/min&#93;$</span>

Although not as advanced, the min REPL is not dissimilar from an OS system shell like Bash, and as a matter of fact, it provides many functionalities that are found in other shells or command prompts, such as:

* Auto-completion
* Persistent line history
* A customizable prompt
* Access to environment variables

...plus in can obviously leverage the entire min language for complex scripting.

## Autocompletion and shortcuts

The min shell features smart tab autocompletion and keyboard shortcut implemented using the [nim-noise](https://github.com/jangko/nim-noise) library.

The following behaviors are implemented when pressing the `TAB` key within:

Context                                                        | Result
---------------------------------------------------------------|--------------
...a string                                                    | Auto-completes the current word using file and directory names.
...a word starting with `!`, `!!`, `!"` `!!"`, `&`, `&"`       | Auto-completes the current word using executable file names.
...a word starting with `$`                                    | Auto-completes the current word using environment variable names.
...a word starting with `'`, `@`, `#`, `>`, `<`, `*`, `(`, `?` | Auto-completes the current word using symbol names.

Additionally, some [additional Emacs-style shortcuts](https://github.com/jangko/nim-noise) are also available.

## Shell configuration files

When the min interpreter is first launched, the following files are created automatically in the $HOME directory (%USERPROFILE% on Windows).

### .minrc

This file is interpreted first every time min is run. By default it is empty, but it can be used to define code to execute at startup.

### .min\_history

This file is used to persist all commands entered in the min shell, and it is loaded in memory at startup to provide line history support.

### .min\_symbols

This files contains all symbol definitions in JSON format that were previously-saved using the {#link-operator||lang||save-symbol#} symbol. Symbols can be loaded using the {#link-operator||lang||load-symbol#} symbol.

{#link-learn||extending||Extending min#}
