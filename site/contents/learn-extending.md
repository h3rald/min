-----
content-type: "page"
title: "Learn: Extending min"
-----
{@ _defs_.md || 0 @}

min provides a fairly complete standard library with many useful modules. However, you may feel the need to extend min in order to perform more specialized tasks.

In such situations, you basically have three options:

* Implement new min modules in min
* Embed min in your [Nim](https://nim-lang.org) program
* Implemet min modules as dynamic libraries in Nim

## Implementing new min modules using min itself

When you just want to create more high-level min operator using functionalities that are already available in min, the easiest way is to create your own reusable min modules.

The {#link-operator||lang||module#} (and the **+** sigil) allows you to create a new min module:

```
(
  (dup *)             :pow2

  (dup dup * *)       :pow3

  (dup dup dup * * *) :pow4
  
) +quickpows

```

Save your code to a file (e.g. *quickpows.min*) and you can use it in other nim files using the {#link-operator||lang||load#} operator and the {#link-operator||lang||import#}:

```
'quickpows load
'quickpows import

2 pow3 pow2 puts ;prints 64
```

## Embedding min in your Nim program

If you'd like to use min as a scripting language within your own program, and maybe extend it by implementing additional operators, you can use min as a Nim library.

To do so:

1. Install min sources using Nifty as explained in the {#link-page||download||Download#} section.
2. Import it in your Nim file.
3. Implement a new `proc` to define the module.

The following code is taken from [HastySite](https://github.com/h3rald/hastysite) and shows how to define a new `hastysite` module containing some symbols (`preprocess`, `postprocess`, `process-rules`, ...):

```
import packages/min/min

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
> For more information on how to create new modules with Nim, have a look in the [lib folder](https://github.com/h3rald/min/tree/master/lib) of the min repository, which contains all the min modules included in the standard library.


## Implementing min modules as dynamic libraries

> %warning%
> Warning
> 
> This technique is currently highly experimental, it has not been tested extensively and it may not even work properly.

If you just want to add a new module to min providing functinalities that cannot be built natively with min operators, you can also implement a min module in Nim and compile it to a dynamic library which can be linked dynamically when min is started.

In order to do this, you don't even need to download the whole min source code, you just need to download the [mindyn.nim](https://github.com/h3rald/min/blob/master/mindyn.nim) file and import it in your Nim program. 

The following code shows how to create a simple min module called *dyntest* containing only a single operator *dynplus*, which essentially returns the sum of two numbers:

```
import mindyn

proc dyntest*(i: In) {.dynlib, exportc.} =

  let def = i.define()

  def.symbol("dynplus") do (i: In):
    let vals = i.expect("num", "num")
    let a = vals[0]
    let b = vals[1]
    if a.isInt:
      if b.isInt:
        i.push newVal(a.intVal + b.intVal)
      else:
        i.push newVal(a.intVal.float + b.floatVal)
    else:
      if b.isFloat:
        i.push newVal(a.floatVal + b.floatVal)
      else:
        i.push newVal(a.floatVal + b.intVal.float)

  def.finalize("dyntest")
```

Note that the `mindym.nim` file contains the signatures of all the `proc`s that are commonly used to define min modules, but not their implementation. Such `proc`s will become available at run time when the dynamic library is linked to the min executable.

You can compile the following library by running the following command:

> %min-terminal%
> [$](class:prompt) nim c \-\-app:lib -d:release \-\-noMain dyntest.nim

If you are using [clang](https://clang.llvm.org/) to compile Nim code, you may need to run the following command instead:

> %min-terminal%
> [$](class:prompt) nim c \-\-app:lib -d:release \-\-noMain  -l:&#34;-undefined dynamic\_lookup&#34; dyntest.nim

Now you should have a `libdyntest.so|dyn|dll` file. To make min load it and link it automatically when it starts, just run:

> %min-terminal%
> [$](class:prompt) min \-\-install:libdyntest.dyn

This command will copy the library file to `$HOME/.minlibs/` (`%HOMEPATH%\.minlibs\` on Windows). min looks for dynamic libraries in this folder when it starts.

> %note%
> Notes
> 
> * The dynamic library file must have the same name as the module it defines (*dyntest* in this case).
> * At startup, min links all your installed dynamic libraries but does not import the modules automatically.

If you wish to uninstall the library, run the following command instead:

> %min-terminal%
> [$](class:prompt) min \-\-uninstall:libdyntest.dyn

