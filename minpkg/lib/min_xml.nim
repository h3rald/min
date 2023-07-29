
import 
    std/xmlparser,
    std/xmltree,
    std/parsexml,
    std/strtabs
import
    ../core/parser,
    ../core/value,
    ../core/interpreter,
    ../core/utils


let xmltypes = "dict:xml-text|dict:xml-verbatim-text|xml-element|xml-cdata|xml-comment"

proc newXDict(i: In, xml: XmlNode): MinValue =
    result = newDict(i.scope)
    case xml.kind:
        of xnText:
            result.objType = "xml-text"
            i.dset(result, "text", xml.text.newVal)
        of xnVerbatimText:
            result.objType = "xml-verbatim-text"
            i.dset(result, "text", xml.text.newVal)
        of xnElement:
            result.objType = "xml-element"
            var children = newSeq[MinValue](0)
            var attributes = newDict(i.scope)
            for child in xml.items:
                children.add i.newXDict(child)
            i.dset(result, "children", children.newVal)
            for attr in xml.attrs.pairs:
                i.dset(attributes, attr.key, attr.value.newVal)
            i.dset(result, "attributes", attributes)
        of xnCData:
            result.objType = "xml-cdata"
            i.dset(result, "text", xml.text.newVal)
        of xnEntity:
            result.objType = "xml-entity"
            i.dset(result, "text", xml.text.newVal)
        of xnComment:
            result.objType = "xml-comment"
            i.dset(result, "text", xml.text.newVal)

proc xml_module*(i: In) =

    let def = i.define()

    def.symbol("xparse") do (i: In):
        let vals = i.expect("str")
        let s = vals[0].getString() 
        try:
            let xml = parseXml(s, {reportComments, allowUnquotedAttribs, allowEmptyAttribs})
            i.push(i.newXDict(xml))
        except CatchableError:
            let msg = getCurrentExceptionMsg()
            raiseInvalid(msg)

    def.symbol("xcomment") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newComment(vals[0].getString))   
    
    def.symbol("xcdata") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newCData(vals[0].getString))  

    def.symbol("xtext") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newText(vals[0].getString))  

    def.symbol("xverbatimtext") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newVerbatimText(vals[0].getString)) 

    def.symbol("xentity") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newEntity(vals[0].getString)) 

    def.symbol("xchildren") do (i: In):
        let vals = i.expect("dict:xml")

    def.finalize("xml")
