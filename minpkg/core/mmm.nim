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


proc init*(MMM: var MinModuleManager) =
    MMM.registry = MMMREGISTRY
    MMM.globalDir = HOME / "mmm"
    MMM.localDir = os.getCurrentDir() / "mmm"
    var updatedLocal = 0
    let mmmJson = MMM.globalDir / "mmm.json"
    if not os.dirExists(MMM.globalDir):
        os.createDir(MMM.globalDir)
    if not os.dirExists(MMM.localDir):
        os.createDir(MMM.localDir)
    if os.fileExists(mmmJson):
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

    
