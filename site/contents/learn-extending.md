-----
content-type: "page"
title: "Learn: Extending min"
-----
{@ _defs_.md || 0 @}

min provides a fairly complete standard library with many useful modules. However, you may feel the need to extend min in order to perform more specialized tasks.

In such situations, you basically have the following options:

* Implementing new min modules using min itself
* Specifying your custom prelude program
* Embedding min in your [Nim](https://nim-lang.org) program

## Implementing new min modules using min itself

When you just want to create more high-level min operator using functionalities that are already available in min, the easiest way is to create your own reusable min modules.

To create a new module, simply create a file containing your operator definitions implemented using either the {#link-operator||lang||operator#} operator or the {#link-operator||lang||lambda#} operator

```
(dup *)             ^pow2
(dup dup * *)       ^pow3
(dup dup dup * * *) ^pow4

```

Save your code to a file (e.g. *quickpows.min*) and you can use it in other nim files using the {#link-operator||lang||require#} operator and the {#link-operator||lang||import#} (if you want to import the operators in the current scope):

```
'quickpows require :qp

2 \*qp/pow3 \*qp/pow2 puts ;prints 64
```

## Specifying your custom prelude program

By default, when min is started it loads the following *prelude.min* program:

```
; Imports
'str       import
'io        import
'logic     import
'num       import
'sys       import
'stack     import
'seq       import
'dict      import
'time      import
'fs        import
'lite? (
  (
    'crypto    import
    'math      import
    'net       import
    'http      import
  ) ROOT with
) unless
; Unseal prompt symbol
'prompt    unseal-symbol
```

Essentially, this causes min to import *all* the modules (except for some if the **lite** flag was defined at compilation time) and unseals the {#link-operator||lang||prompt#} symbol so that it can be customized. If you want, you can provide your own prelude file to specify your custom behaviors, selectively import modules, and define your own symbols, like this:

> %min-terminal%
> [$](class:prompt) min -i -p:myfile.min

## Embedding min in your Nim program

If you'd like to use min as a scripting language within your own program, and maybe extend it by implementing additional operators, you can use min as a Nim library.

To do so:

1. Install min sources using Nifty as explained in the {#link-page||download||Download#} section.
2. Import it in your Nim file.
3. Implement a new `proc` to define the module.

The following code is taken from [HastySite](https://github.com/h3rald/hastysite) and shows how to define a new `hastysite` module containing some symbols (`preprocess`, `postprocess`, `process-rules`, ...):

```
import min

proc hastysite_module*(i: In, hs1: HastySite) =
  var hs = hs1
  let def = i.define()
  
  def.symbol("preprocess") do (i: In):
    hs.preprocess()

   def.symbol("postprocess") do (i: In):
    hs.postprocess()

  def.symbol("process-rules") do (i: In):
    hs.interpret(hs.files.rules)

  # ...

  def.finalize("hastysite")
```

Then you need to:

4. Instantiate a new min interpreter using the `newMinInterpreter` proc.
5. Run the `proc` used to define the module.
6. Call the `interpret` method to interpret a min file or string:

```
proc interpret(hs: HastySite, file: string) =
  var i = newMinInterpreter(file, file.parentDir)
  i.hastysite_module(hs)
  i.interpret(newFileStream(file, fmRead))
```

> %tip%
> Tip
> 
> For more information on how to create new modules with Nim, have a look in the [lib folder](https://github.com/h3rald/min/tree/master/minpkg/lib) of the min repository, which contains all the min modules included in the standard library.

