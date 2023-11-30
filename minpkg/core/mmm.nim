import 
    std/[json,
    os,
    httpclient,
    strutils,
    sequtils,
    logging
]
import
    env



type
    MinModuleManager* = object
        registry: string
        modules = %[]
        globalDir: string
        localDir: string
    MMMError = ref object of CatchableError
    MMMAlreadyInstalledError = ref object of MMMError


proc raiseError(msg: string) = 
    raise MMMError(msg: msg)

proc raiseAlreadyInstalledError(msg: string) = 
    raise MMMAlreadyInstalledError(msg: msg)


proc setup*(MMM: var MinModuleManager, check = true) =
    MMM.registry = MMMREGISTRY
    MMM.globalDir = HOME / "mmm"
    MMM.localDir = getCurrentDir() / "mmm"
    var updatedLocal = 0
    let mmmJson = MMM.globalDir / "mmm.json"
    if not dirExists(MMM.globalDir):
        createDir(MMM.globalDir)
    if not dirExists(MMM.localDir):
        createDir(MMM.localDir)
    if fileExists(mmmJson):
        try:
            let data = parseFile(mmmJson)
            updatedLocal = data["updated"].getInt
            MMM.modules = data["modules"]
        except CatchableError:
            debug getCurrentExceptionMsg()
            raiseError "Invalid local registry data ($#)" % [mmmJson]
    if check:
        let client = newHttpClient()
        # Check remote data
        var updatedRemote = 0
        try:
            debug "Checking remote registry"
            updatedRemote = client.getContent(MMMREGISTRY & "/mmm.timestamp").parseInt
            debug "Remote registry timestamp retrieved."
        except CatchableError:
            debug getCurrentExceptionMsg()
            warn "Unable to connect to remote registry ($#)" % [MMMREGISTRY]
        if updatedRemote > updatedLocal:
            notice "Updating local module registry"
            try:
                client.downloadFile(MMMREGISTRY & "/mmm.json", mmmJson)
            except CatchableError:
                warn "Unable to download remote registry data ($#)" % [MMMREGISTRY & "/mmm.json"]
                debug getCurrentExceptionMsg()
            try:
                let data = parseFile(mmmJson)
                MMM.modules = data["modules"]
            except CatchableError:
                debug getCurrentExceptionMsg()
                raiseError "Invalid local registry data ($#)" % [mmmJson]
        else:
            debug "Local registry up-to-date: $#" % [$updatedLocal] 

proc init*(MMM: var MinModuleManager) =
    let pwd = getCurrentDir()
    if dirExists(pwd / "mmm.json"):
        raiseError "The current directory already contains a managed module (mmm.json already exists)"
    debug "Creating mmm.json file"
    let json = """
{
    "name": "$#",
    "author": "TBD",
    "description": "TBD",
    "license": "MIT",
    "private": true,
    "deps": {}
}
    """ % [pwd.lastPathPart]
    writeFile(pwd / "mmm.json", json)
    if not dirExists(pwd / "mmm"):
        debug "Creating mmm directory"
        createDir(pwd / "mmm")
    notice "Created a mmm.json file in the current directory"
    
proc uninstall*(MMM: var MinModuleManager, name, version: string, global = false) =
    var dir: string
    var versionLabel = version
    if version == "":
        versionLabel = "<all-versions>"
        if global:
            dir = MMM.globalDir / name
        else:
            dir = MMM.localDir / name
    else:
        if global:
            dir = MMM.globalDir / name / version
        else:
            dir = MMM.localDir / name / version
    if not dir.dirExists():
        raiseError "Module '$#' (version: $#) is not installed." % [name, versionLabel]
    notice "Uninstalling module $#@$#..." % [name, versionLabel]
    try:
        dir.removeDir()
        if version != "" and dir.parentDir().walkDir().toSeq().len == 0:
            # Remove parent directory if no versions are installed
            dir.parentDir().removeDir()
    except CatchableError:
        debug getCurrentExceptionMsg()
        raiseError "Unable to uninstall module $#@$#" % [name, versionLabel]
    notice "Uninstall complete."

proc uninstall*(MMM: var MinModuleManager) =
    try:
        notice "Uninstalling all local managed modules..."
        MMM.localDir.removeDir()
        notice "Done."
    except CatchableError:
        raiseError "Unable to uninstall local managed modules."

proc install*(MMM: var MinModuleManager, name, version: string, global = false) =
    var dir: string
    if global:
        dir = MMM.globalDir / name / version
    else:
        dir = MMM.localDir / name / version
    if dir.dirExists():
        raiseAlreadyInstalledError "Module '$#' (version: $#) is already installed." % [name, version]
    dir.createDir()
    let results = MMM.modules.filterIt(it.hasKey("name") and it["name"] == %name)
    if results.len == 0:
        raiseError "Unknown module '$#'." % [name]
    let data = results[0]
    if not data.hasKey("method"):
        raiseError "Installation method not specified for module '$#'" % [name]
    let meth = data["method"].getStr 
    if meth != "git":
        raiseError "Unable to install module '$#': Installation method '$#' is not supported" % [name, meth]
    if not data.hasKey("url"):
        raiseError "URL not specified for module '$#'" % [name]
    let url = data["url"].getStr
    let cmd = "git clone $# -b $# --depth 1 \"$#\"" % [url, version, dir.replace("\\", "/")]
    debug cmd
    notice "Installing module $#@$#..." % [name, version]
    if not data.hasKey("deps"):
        raiseError "Dependencies not specified for module '$#'" % [name]
    var result = execShellCmd(cmd)
    if (result == 0):
        # Go to directory and install dependencies
        let originalDir = getCurrentDir()
        dir.setCurrentDir()
        MMM.setup(false)
        if data["deps"].pairs.toSeq().len > 0:
            notice "Installing dependencies..."
        for depName, depVersion in data["deps"].pairs:
            try:
                MMM.install depName, depVersion.getStr, global
            except CatchableError:
                warn getCurrentExceptionMsg()
                originalDir.setCurrentDir()
                result = 1
                break
    if result != 0:
        # Rollback
        warn "Installation failed - Rolling back..."
        try:
            MMM.setup(false)
            MMM.uninstall(name, version, global)
            notice "Rollback completed."
        except:
            debug getCurrentExceptionMsg()
            warn "Rollback failed."
        finally:
            raiseError "Installation failed."

proc install*(MMM: var MinModuleManager) =
    let mmmJson = getCurrentDir() / "mmm.json"
    if not mmmJson.fileExists:
        raiseError "No mmm.json file found in the current directory."
    let data = mmmJson.parseFile
    if not data.hasKey "deps":
        raiseError "No 'deps' key present in the mmm.json file in the current directory."
    for name, v in data["deps"].pairs:
        let version = v.getStr
        try:
            MMM.install name, version
        except MMMAlreadyInstalledError:
            warn getCurrentExceptionMsg()
            continue
        except CatchableError:
            debug getCurrentExceptionMsg()
            warn "Installation of module $#@$# failed - Rolling back..." % [name, version]
            try:
                MMM.setup(false)
                MMM.uninstall(name, version)
                notice "Rollback completed."
            except:
                debug getCurrentExceptionMsg()
                warn "Rollback failed."
            finally:
                raiseError "Installation failed."

proc update*(MMM: var MinModuleManager, name, version: string, global = false) =
    var dir: string
    if global:
        dir = MMM.globalDir / name / version
    else:
        dir = MMM.localDir / name / version
    if not dir.dirExists():
        raiseError "Module '$#' (version: $#) is not installed." % [name, version]
    # Read local mmm.json
    let mmmJson = dir / "mmm.json"
    if not mmmJson.fileExists:
        raiseError "No mmm.json file found for managed module $#@$#" % [name, version]
    var data: JsonNode
    try:
        data = mmmJson.parseFile
    except CatchableError:
        raiseError "Unable to parse mmm.json file for managed module $#@$#" % [name, version]
    if not data.hasKey("method"):
        raiseError "Installation method not specified for module '$#'" % [name]
    let meth = data["method"].getStr 
    if meth != "git":
        raiseError "Unable to install module '$#': Installation method '$#' is not supported" % [name, meth]
    if not data.hasKey("url"):
        raiseError "URL not specified for module '$#'" % [name]
    let url = data["url"].getStr
    let cmd = "git -C \"$#\" pull" % [dir.replace("\\", "/"), url, version]
    debug cmd
    notice "Updating module $#@$#..." % [name, version]
    if not data.hasKey("deps"):
        raiseError "Dependencies not specified for module '$#'" % [name]
    var result = execShellCmd(cmd)
    if (result == 0):
        # Go to directory and install dependencies
        dir.setCurrentDir()
        MMM.setup(false)
        if data["deps"].pairs.toSeq().len > 0:
            notice "Updating dependencies..."
        for depName, depVersion in data["deps"].pairs:
            try:
                MMM.update depName, depVersion.getStr, global
            except CatchableError:
                warn getCurrentExceptionMsg()
                raiseError "Update of module '$#@$#' failed." % [name, version]

proc update*(MMM: var MinModuleManager) =
    let mmmJson = getCurrentDir() / "mmm.json"
    if not mmmJson.fileExists:
        raiseError "No mmm.json file found in the current directory."
    let data = mmmJson.parseFile
    if not data.hasKey "deps":
        raiseError "No 'deps' key present in the mmm.json file in the current directory."
    for name, v in data["deps"].pairs:
        let version = v.getStr
        try:
            MMM.update name, version
        except CatchableError:
            debug getCurrentExceptionMsg()
            warn "Update of module '$#@$#' failed." % [name, version]


