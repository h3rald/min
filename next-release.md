* Added the possibility to "compile" min files into single executables. This is achieved by converting the specified min file to its raw Nim code equivalent and then calling the Nim compiler (which in turns calls the C compiler).
* Added **compiled?** symbol which returns true if the program has been compiled.
* Added the possibility of including a path containing additional **.min** files to compile along with the main file (**-m**, **--module-path**).
* Added the possibility to compile a bare-bones version of min specifying the **-d:mini** compilation flag.
* Added **mini?** symbol which returns true if min was compiled specifying **-d:mini**.
* Now distributing precompiled **litemin** and **minimin** executables as well.
* Moved **puts**, **puts!** and **gets** from io module to lang module.
