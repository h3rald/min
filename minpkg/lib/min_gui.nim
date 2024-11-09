import std/sequtils

import pkg/fenstim

import
    ../core/parser,
    ../core/interpreter,
    ../core/value,
    ../core/utils

var WINDOWS*: seq[Fenster] = @[]

proc window(i: In, v: MinValue): var Fenster =
    return WINDOWS[i.dget(v, "ref").intVal]

proc close(i: In, v: MinValue) =
    i.window(v).close()
    let r = i.dget(v, "ref").intVal
    WINDOWS.delete(r)

proc gui_module*(i: In) =
    let def = i.define()

    def.symbol("window") do (i: In):
        let vals = i.expect("dict")
        var d = vals[0]
        var title = "min"
        var height = 400
        var width = 400
        var fps = 60
        if d.dhas("title"):
            title = i.dget(d, "title").getString
        if d.dhas("height"):
            height = i.dget(d, "height").intVal
        if d.dhas("width"):
            width = i.dget(d, "width").intVal
        if d.dhas("fps"):
            fps = i.dget(d, "fps").intVal
        var window = Fenster.init(title, width, height, fps)
        var win = newDict(i.scope)
        win = i.dset(win, "title", title.newVal)
        win = i.dset(win, "height", height.newVal)
        win = i.dset(win, "width", width.newVal)
        win = i.dset(win, "fps", fps.newVal)
        win = i.dset(win, "ref", WINDOWS.len.newVal)
        win.objType = "window"
        WINDOWS.add window
        i.push win

    def.symbol("loop") do (i: In):
        var vals = i.expect("quot", "dict:window")
        while i.window(vals[1]).loop:
            i.dequote vals[0]

    def.symbol("close") do (i: In):
        var vals = i.expect("dict:window")
        i.close(vals[0])

    def.symbol("pixel") do (i: In):
        var vals = i.expect("quot", "dict:window")
        i.push i.window(vals[1]).pixel(vals[0].qVal[0].intVal, vals[0].qVal[
                1].intVal).int.newVal

    def.symbol("draw") do (i: In):
        var vals = i.expect("int", "quot", "dict:window")
        var f = i.window(vals[2])
        let x = vals[1].qVal[0].intVal
        let y = vals[1].qVal[1].intVal
        let v = vals[0].intVal.uint32
        f.pixel(x, y) = v

    def.symbol("width") do (i: In):
        var vals = i.expect("dict:window")
        i.push i.window(vals[0]).width.newVal

    def.symbol("height") do (i: In):
        var vals = i.expect("dict:window")
        i.push i.window(vals[0]).height.newVal

    def.symbol("keys") do (i: In):
        var vals = i.expect("dict:window")
        i.push i.window(vals[0]).keys.mapIt(it.int.newVal).newVal

    def.symbol("modkey") do (i: In):
        var vals = i.expect("dict:window")
        i.push i.window(vals[0]).modkey.newVal

    def.symbol("mouse") do (i: In):
        var vals = i.expect("dict:window")
        var win = i.window(vals[0])
        var mouse = newDict(i.scope)
        # Double quote quotations
        let click = @[win.mouse.mclick.mapIt(
                it.int.newVal).newVal].newVal
        let hold = @[win.mouse.mhold.mapIt(
                it.int.newVal).newVal].newVal
        i.dset(mouse, "x", win.mouse.pos.x.newVal)
        i.dset(mouse, "y", win.mouse.pos.y.newVal)
        i.dset(mouse, "click", click)
        i.dset(mouse, "hold", hold)
        i.push mouse

    def.symbol("sleep") do (i: In):
        var vals = i.expect("int", "dict:window")
        i.window(vals[1]).sleep(vals[0].intVal)

    def.symbol("time") do (i: In):
        var vals = i.expect("dict:window")
        i.push i.window(vals[0]).time.newVal

    def.symbol("clear") do (i: In):
        var vals = i.expect("dict:window")
        i.window(vals[0]).clear()

    def.finalize("gui")
