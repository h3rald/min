import 
    std/[json,
    os,
    httpclient,
    strutils,
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


proc setup*(MMM: var MinModuleManager) =
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
            logging.debug getCurrentExceptionMsg()
            error "Invalid local registry data ($#)" % [mmmJson]
    let client = newHttpClient()
    # Check remote data
    var updatedRemote = 0
    try:
        logging.debug "Checking remote registry..."
        updatedRemote = client.getContent(MMMREGISTRY & "/mmm.timestamp").parseInt
        logging.debug "Remote registry timestamp retrieved."
    except CatchableError:
        logging.debug getCurrentExceptionMsg()
        logging.warn "Unable to connect to remote registry ($#)" % [MMMREGISTRY]
    if updatedRemote > updatedLocal:
        logging.notice "Updating local module registry..."
        try:
            client.downloadFile(MMMREGISTRY & "/mmm.json", mmmJson)
        except CatchableError:
            logging.debug getCurrentExceptionMsg()
            logging.warn "Unable to download remote registry data ($#)" % [MMMREGISTRY & "/mmm.json"]
        try:
            let data = parseFile(mmmJson)
            MMM.modules = data["modules"]
        except CatchableError:
            logging.debug getCurrentExceptionMsg()
            error "Invalid local registry data ($#)" % [mmmJson]
    else:
        logging.debug "Local registry up-to-date: $#" % [$updatedLocal] 

proc init*(MMM: var MinModuleManager) =
    let pwd = getCurrentDir()
    if dirExists(pwd / "mmm.json"):
        error "The current directory already contains a managed module (mmm.json already exists)"
    logging.debug "Creating mmm.json file"
    let json = """
{
    "name": "$#",
    "method": "git",
    "url": "",
    "author": "",
    "description": "",
    "license": "",
    "deps": {}
}
    """ % [pwd.lastPathPart]
    writeFile(pwd / "mmm.json", json)
    if not dirExists(pwd / "mmm"):
        logging.debug "Creating mmm directory"
        createDir(pwd / "mmm")
    
