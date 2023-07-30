
import 
    std/xmlparser,
    std/xmltree,
    std/parsexml,
    std/strtabs,
    std/critbits,
    nimquery
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
            i.dset(result, "tag", xml.tag.newVal)
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

proc newXml(i: In, xdict: MinValue): XmlNode =
     case xdict.objType:
        of "xml-text":
            result = newText(i.dget(xdict, "text").getString)
        of "xml-verbatim-text":
            result = newVerbatimText(i.dget(xdict, "text").getString)
        of "xml-element":
            let tag = i.dget(xdict, "tag").getString
            let attributes = i.dget(xdict, "attributes")
            let children = i.dget(xdict, "children")
            result = newElement(tag)
            var attrs = newSeq[tuple[key, val: string]](0)
            for attr in i.keys(attributes).qVal:
                let key = attr.getString
                let val = i.dget(attributes, attr).getString
                attrs.add {key: key, val: val}
            result.attrs = attrs.toXmlAttributes
            for child in children.qVal:
                result.add i.newXml(child)
        of "xml-cdata":
            result = newCdata(i.dget(xdict, "text").getString)
        of "xml-entity":
            result = newEntity(i.dget(xdict, "text").getString)
        of "xml-comment":
            result = newComment(i.dget(xdict, "text").getString)

proc xml_module*(i: In) =

    let def = i.define()

    i.scope.symbols["xml-node"] = MinOperator(kind: minValOp, val: xmltypes.newVal, sealed: false, quotation: false)

    def.symbol("from-xml") do (i: In):
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

    def.symbol("xelement") do (i: In):
        let vals = i.expect("'sym")
        i.push i.newXDict(newElement(vals[0].getString))

    def.symbol("to-xml") do (i: In):
        let vals = i.expect("dict:xml-node")
        let xdict = vals[0]
        let xml = i.newXml(xdict)
        i.push ($xml).newVal

    def.symbol("xquery") do (i: In):
        let vals = i.expect("dict:xml-element", "'sym")
        let xdict = vals[0]
        let query = vals[1].getString
        let root = i.newXml(xdict)
        i.push i.newXDict(root.querySelector(query))

    def.finalize("xml")
