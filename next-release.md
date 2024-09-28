### BREAKING CHANGES

- All symbols defined in the **num** module have been moved to the **global** module.
- All symbols defined in the **logic** module have been moved to the **global** module.
- All symbols defined in the **str** module have been moved to the **global** module.
- All symbols defined in the **seq** module have been moved to the **global** module.
- Removed **lambdabind** (use **lambda-bind** instead).
- The **stack** module is no longer imported.
- **stack** module: removed symbol **id**.
- **stack** module: renamed **clear-stack** to **clear**.
- **stack** module: removed **clearstack** (use **stack.clear** instead).
- **stack** module: renamed **get-stack** to **get**.
- **stack** module: removed **getstack** (use **stack.get** instead).
- **stack** module: renamed **set-stack** to **set**.
- **stack** module: removed **setstack** (use **stack.set** instead).
- The **io** module is no longer imported.
- **io** module: renamed **fwrite** and **write** to **fs.write**
- **io** module: renamed **fread** and **read** to **fs.read**
- **io** module: renamed **fappend** to **fs.append**
- **io** module: moved **print** to the **global** module.
- **io** module: removed **newline** (use `"" puts!` instead).
- The **fs** module is no longer imported.
- **fs** module: renamed **fperms** to **fs.permissions**
- **fs** module: renamed **fsize** to **fs.size**
- **fs** module: renamed **fstats** to **fs.stats**
- **fs** module: renamed **ftype** to **fs.type**
- The **time** module is no longer imported.
- **time** module: renamed **tformat** to **time.format**
- **time** module: renamed **timeinfo** to **time.info**
- **time** module: renamed **timestamp** to **time.stamp**



### New Features

### Fixes and Improvements


