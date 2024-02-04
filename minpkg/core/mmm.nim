import
    std/[json,
    os,
    osproc,
    httpclient,
    strutils,
    sequtils,
    logging,
    algorithm
]
import
    env



type
    MinModuleManager* = object
        registry: string
        modules = %[]
        globalDir*: string
        localDir*: string
    MMMError = ref object of CatchableError
    MMMAlreadyInstalledError = ref object of MMMError


proc raiseError(msg: string) =
    raise MMMError(msg: msg)

proc raiseAlreadyInstalledError(msg: string) =
    raise MMMAlreadyInstalledError(msg: msg)

proc getDefaultGitBranch(repo: string): string =
    let res = execCmdEx("git remote show $#" % [repo])
    return res.output.splitLines().filterIt(it.contains("HEAD branch:"))[
            0].split(":")[1].strip

proc getModuleByName(MMM: var MinModuleManager, name: string): JsonNode =
    let match = MMM.modules.filterIt(it.hasKey("name") and it["name"] == %name)
    if match.len == 0:
        raiseError "Module '$#' not found." % [name]
    return match[0]

proc forbidLocalModulesInGlobalDir(MMM: var MinModuleManager, op: string) =
    if MMM.localDir == MMM.globalDir or MMM.localDir.startsWith(
            MMM.globalDir/"mmm"):
        raiseError "Cannot $# a module in the global directory without specifying -g." %
                [op]

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
            updatedRemote = client.getContent(MMMREGISTRY &
                    "/mmm.timestamp").parseInt
            debug "Remote registry timestamp retrieved."
        except CatchableError:
            debug getCurrentExceptionMsg()
            warn "Unable to connect to remote registry ($#)" % [MMMREGISTRY]
        if updatedRemote > updatedLocal:
            notice "Updating local module registry"
            try:
                client.downloadFile(MMMREGISTRY & "/mmm.json", mmmJson)
            except CatchableError:
                warn "Unable to download remote registry data ($#)" % [
                        MMMREGISTRY & "/mmm.json"]
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
    if fileExists(pwd / "mmm.json"):
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

proc uninstall*(MMM: var MinModuleManager, name, v: string, global = false) =
    forbidLocalModulesInGlobalDir(MMM, "uninstall")
    var dir: string
    var version = v
    var versionLabel = version
    if version == "*":
        versionLabel = "<all-versions>"
        if global:
            dir = MMM.globalDir / name
        else:
            dir = MMM.localDir / name
    else:
        if version == "":
            let url = MMM.getModuleByName(name)["url"].getStr
            try:
                version = getDefaultGitBranch(url)
                versionLabel = version
            except CatchableError:
                raiseError "Unable to determine default branch for module '$#'" %
                        [name]
        if global:
            dir = MMM.globalDir / name / version
        else:
            dir = MMM.localDir / name / version
    debug "Directory: $#" % [dir]
    let pwd = getCurrentDir()
    if not global and not fileExists(pwd / "mmm.json"):
        raiseError "mmm.json not found in current directory. Please run min init to initialize your managed module."
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
    if not global:
        let mmmJson = pwd/"mmm.json"
        var data = mmmJson.parseFile
        if data["deps"].hasKey name:
            data["deps"].delete(name)
        mmmJson.writeFile(data.pretty)
    notice "Uninstall complete."


proc uninstall*(MMM: var MinModuleManager, nameAndVersion: string,
        global = false) =
    let parts = nameAndVersion.split("@")
    if parts.len != 2:
        MMM.uninstall nameAndVersion, "", global
        return
    let name = parts[0]
    let version = parts[1]
    MMM.uninstall name, version, global

proc uninstall*(MMM: var MinModuleManager) =
    forbidLocalModulesInGlobalDir(MMM, "uninstall")
    let pwd = getCurrentDir()
    if not fileExists(pwd / "mmm.json"):
        raiseError "mmm.json not found in current directory. Please run min init to initialize your managed module."
    try:
        notice "Uninstalling all local managed modules..."
        MMM.localDir.removeDir()
        notice "Done."
    except CatchableError:
        raiseError "Unable to uninstall local managed modules."

proc install*(MMM: var MinModuleManager, name, v: string, global = false) =
    forbidLocalModulesInGlobalDir(MMM, "install")
    var version = v
    var dir: string
    let pwd = getCurrentDir()
    let results = MMM.modules.filterIt(it.hasKey("name") and it["name"] == %name)
    if results.len == 0:
        raiseError "Unknown module '$#'." % [name]
    let data = results[0]
    if not data.hasKey("method"):
        raiseError "Installation method not specified for module '$#'" % [name]
    let meth = data["method"].getStr
    if meth != "git":
        raiseError "Unable to install module '$#': Installation method '$#' is not supported" %
                [name, meth]
    if not data.hasKey("url"):
        raiseError "URL not specified for module '$#'" % [name]
    let url = data["url"].getStr
    if version == "":
        try:
            version = getDefaultGitBranch(url)
        except CatchableError:
            raiseError "Unable to determine default branch for module '$#'" % [name]
    if global:
        dir = MMM.globalDir / name / version
    else:
        dir = MMM.localDir / name / version
        if not fileExists(pwd / "mmm.json"):
            raiseError "mmm.json not found in current directory. Please run min init to initialize your managed module."
    if dir.dirExists():
        raiseAlreadyInstalledError "Module '$#' (version: $#) is already installed." %
                [name, version]
    dir.createDir()
    let cmd = "git clone $# -b $# --depth 1 \"$#\"" % [url, version,
            dir.replace("\\", "/")]
    debug cmd
    notice "Installing module $#@$#..." % [name, version]
    if not data.hasKey("deps"):
        raiseError "Dependencies not specified for module '$#'" % [name]
    var result = execShellCmd(cmd)
    if result == 0:
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
    # re-check if dependency installation failed.
    if result == 0:
        if not global:
            # Add dependency to current dir's mmm.json file.
            let mmmJson = dir/"mmm.json"
            var data = mmmJson.parseFile
            data["deps"][name] = %($version)
            mmmJson.writeFile(data.pretty)
    else:
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

proc install*(MMM: var MinModuleManager, nameAndVersion: string,
        global = false) =
    let parts = nameAndVersion.split("@")
    if parts.len != 2:
        MMM.install nameAndVersion, "", global
        return
    let name = parts[0]
    let version = parts[1]
    MMM.install name, version, global

proc install*(MMM: var MinModuleManager) =
    forbidLocalModulesInGlobalDir(MMM, "install")
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
            warn "Installation of module $#@$# failed - Rolling back..." % [
                    name, version]
            try:
                MMM.setup(false)
                MMM.uninstall(name, version)
                notice "Rollback completed."
            except:
                debug getCurrentExceptionMsg()
                warn "Rollback failed."
            finally:
                raiseError "Installation failed."

proc generateRunScript*(MMM: var MinModuleManager, id: string): string =
    var name, version: string
    if (id.contains("@")):
        let parts = id.split("@")
        name = parts[0]
        version = parts[1]
    else:
        name = id
        let data = MMM.getModuleByName(name)
        debug data
        version = getDefaultGitBranch(data["url"].getStr)
    if not dirExists(MMM.globalDir / name / version):
        try:
            MMM.install name, version, true
        except CatchableError:
            debug getCurrentExceptionMsg()
            raiseError "Unable to install module $#@$#." % [name, version]
    let script = """
'$1 require :$1
($1 'main dhas?)
  (*$1/main)
  ("Managed module \"$1\" does not expose a 'main' symbol." error)
if
""" % [name]
    debug "Generated run script:\n $#." % [script]
    return script

proc update*(MMM: var MinModuleManager, name, v: string, global = false) =
    forbidLocalModulesInGlobalDir(MMM, "update")
    var version = v
    var dir: string
    if version == "":
        try:
            let url = MMM.getModuleByName(name)["url"].getStr
            version = getDefaultGitBranch(url)
        except CatchableError:
            raiseError "Unable to determine default branch for module '$#'" % [name]
    if global:
        dir = MMM.globalDir / name / version
    else:
        dir = MMM.localDir / name / version
    debug "Dir: $#" % [dir]
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
        raiseError "Unable to parse mmm.json file for managed module $#@$#" % [
                name, version]
    if not data.hasKey("method"):
        raiseError "Installation method not specified for module '$#'" % [name]
    let meth = data["method"].getStr
    if meth != "git":
        raiseError "Unable to install module '$#': Installation method '$#' is not supported" %
                [name, meth]
    if not data.hasKey("url"):
        raiseError "URL not specified for module '$#'" % [name]
    let url = data["url"].getStr
    let cmd = "git -C \"$#\" pull" % [dir.replace("\\", "/"), url, version]
    debug cmd
    notice "Updating module $#@$#..." % [name, version]
    if not data.hasKey("deps"):
        raiseError "Dependencies not specified for module '$#'" % [name]
    var result = execShellCmd(cmd)
    if result == 0:
        # Go to directory and install dependencies
        dir.setCurrentDir()
        MMM.setup(false)
        if data["deps"].pairs.toSeq().len > 0:
            notice "Updating dependencies..."
        for depName, depVersion in data["deps"].pairs:
            try:
                debug "Updating dep: $#@$# (global: $#)" % [depName,
                        depVersion.getStr, $global]
                MMM.update depName, depVersion.getStr, global
            except CatchableError:
                warn getCurrentExceptionMsg()
                raiseError "Update of module '$#@$#' failed." % [name, version]

proc update*(MMM: var MinModuleManager, nameAndVersion: string,
        global = false) =
    let parts = nameAndVersion.split("@")
    if parts.len != 2:
        MMM.update nameAndVersion, "", global
        return
    let name = parts[0]
    let version = parts[1]
    MMM.update name, version, global

proc update*(MMM: var MinModuleManager) =
    forbidLocalModulesInGlobalDir(MMM, "update")
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

proc search*(MMM: var MinModuleManager, search = "") =
    let rateModule = proc(it: JsonNode): JsonNode =
        var score = 0
        if it["name"].getStr.contains(search):
            score += 4
        if it["description"].getStr.contains(search):
            score += 2
        if it["author"].getStr.contains(search):
            score += 1
        it["score"] = %score
        return it
    let sortModules = proc(x, y: JsonNode): int =
        cmp(x["score"].getInt, y["score"].getInt)
    let formatDeps = proc(deps: JsonNode): string =
        result = deps.pairs.toSeq().mapIt("$#@$#" % [it.key,
                it.val.getStr]).join(", ")
        if result == "":
            result = "n/a"
    var results = MMM.modules.getElems().map(rateModule).filterIt(it[
            "score"].getInt > 0)
    results.sort(sortModules)
    var msg = "$# results found:"
    if results.len == 1:
        msg = "$# result found:"
    elif results.len == 0:
        msg = "No results found."
    notice msg % [$results.len]
    for m in results:
        notice "-> $#" % [m["name"].getStr]
        notice "   Description: $#" % [m["description"].getStr]
        notice "   Author: $#" % [m["author"].getStr]
        notice "   License: $#" % [m["license"].getStr]
        notice "   Dependencies: $#" % [m["deps"].formatDeps]

proc list*(MMM: var MinModuleManager, dir: string, level = 0) =
    debug "Directory: " & dir
    if not dir.dirExists:
        return
    for name in dir.walkDir:
        debug "Module directory: " & name.path
        if name.kind == pcDir or name.kind == pcLinkToDir:
            for version in (name.path).walkDir:
                debug "Module version directory: " & version.path
                if name.kind == pcDir or name.kind == pcLinkToDir:
                    notice " ".repeat(level) & "$#@$#" % [
                            name.path.lastPathPart, version.path.lastPathPart]
                    MMM.list version.path/"mmm", level+1

