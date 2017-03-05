-----
content-type: page
title: Download
-----
You can download one of the following pre-built min binaries:

* {#release||0.4.0||osx||macOS||x64#}
* {#release||0.4.0||windows||Windows||x64#}
* {#release||0.4.0||linux||Linux||x64#}
* {#release||0.4.0||linux||Linux||x86#}
* {#release||0.4.0||linux||Linux||arm#}


{#release -> [min v$1 for $3 ($4)](https://github.com/h3rald/min/releases/download/v$1/min\_v$1\_$2\_$4.zip) #}

## Building from Source

Alternatively, you can build min from source as follows:

1. Download and install [nim](https://nim-lang.org).
2. Download and build [Nifty](https://github.com/h3rald/nifty), and put the nifty executable somewhere in your $PATH.
3. Clone the min [repository](https://github.com/h3rald/hastyscribe).
4. Navigate to the min repository local folder.
5. Run **nifty install** to download min’s dependencies.
7. Run **nim c -d:release min.nim**.

