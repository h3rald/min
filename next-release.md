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
- The **dict** module is no longer imported.
- **dict** module: renamed **dhas?** to **dict.has?**
- **dict** module: renamed **dget** to **dict.get**
- **dict** module: renamed **dget-raw** to **dict.get-raw**
- **dict** module: renamed **dset** to **dict.set**
- **dict** module: renamed **dset-sym** to **dict.set-sym**
- **dict** module: renamed **ddel** to **dict.del**
- **dict** module: renamed **dkeys** to **dict.keys**
- **dict** module: renamed **dvalues** to **dict.values**
- **dict** module: renamed **dpairs** to **dict.pairs**
- **dict** module: renamed **ddup** to **dict.dup**
- **dict** module: renamed **dpick** to **dict.pick**
- **dict** module: renamed **dtype** to **dict.type**
- The **sys** module is no longer imported. 
- The **dstore** module is no longer imported. 
- **dstore** mdule: renamed **dsinit** to **dstore.init**
- **dstore** mdule: renamed **dsget** to **dstore.get**
- **dstore** mdule: renamed **dshas?** to **dstore.has?**
- **dstore** mdule: renamed **dsput** to **dstore.put**
- **dstore** mdule: renamed **dspost** to **dstore.post**
- **dstore** mdule: renamed **dsdelete** to **dstore.delete**
- **dstore** mdule: renamed **dsquery** to **dstore.query**
- **dstore** mdule: renamed **dswrite** to **dstore.write**
- **dstore** mdule: renamed **dsread** to **dstore.read**



### New Features

### Fixes and Improvements


