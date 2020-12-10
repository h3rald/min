* Added the possibility to "compile" min files into sibgle executables. This is achieved by converting the specified min file to its raw nim code equivalent and then calling the Nim compiler (which in turns calls the C compiler).
* Added **compiled?** symbol which returns true if the program has been compiled.
