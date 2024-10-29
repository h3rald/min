import std/sequtils

import pkg/fenstim

import 
    ../core/parser,
    ../core/interpreter,
    ../core/value,
    ../core/utils

type Window = ref Fenster

proc toFenster(q: MinValue): var Fenster =
  return cast[var Fenster](q.obj)

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
        var app = Fenster.init(title, width, height, fps)
        var winRef = Window(raw: app.raw, targetFps: app.targetFps, lastFrameTime: app.lastFrameTime, fps: app.fps)
        var win = newDict(i.scope)
        win = i.dset(win, "title", title.newVal)
        win = i.dset(win, "height", height.newVal)
        win = i.dset(win, "width", width.newVal)
        win = i.dset(win, "fps", fps.newVal)
        win.objType = "window"
        win.obj = winRef[].addr
        i.push win

    def.symbol("loop") do (i: In):
        var vals = i.expect("quot", "dict:window")
        var win = vals[1].toFenster
        while win.loop:
            i.dequote vals[0]
    
    def.symbol("close") do (i: In):
        var vals = i.expect("dict:window")
        vals[0].toFenster.close()

    def.symbol("pixel") do (i: In):
        var vals = i.expect("quot", "dict:window")
        i.reqQuotationOfIntegers(vals[0])
        i.push vals[1].toFenster.pixel(vals[0].qVal[0].intVal, vals[1].qVal[0].intVal).int.newVal

    def.symbol("draw") do (i: In):
        var vals = i.expect("int", "quot", "dict:window")
        vals[2].toFenster.pixel(vals[1].qVal[0].intVal, vals[1].qVal[1].intVal) = vals[0].intVal.uint32

    def.symbol("width") do (i: In):
        var vals = i.expect("dict:window")
        i.push vals[0].toFenster.width.newVal

    def.symbol("height") do (i: In):
        var vals = i.expect("dict:window")
        i.push vals[0].toFenster.height.newVal

    def.symbol("keys") do (i: In):
        var vals = i.expect("dict:window")
        i.push vals[0].toFenster.keys.mapIt(it.int.newVal).newVal

    def.symbol("modkey") do (i: In):
        var vals = i.expect("dict:window")
        i.push vals[0].toFenster.modkey.newVal

    def.symbol("mouse") do (i: In):
        var vals = i.expect("dict:window")
        var win = vals[0].toFenster
        var mouse = newDict(i.scope)
        i.dset(mouse, "x", win.mouse.pos.x.newVal)
        i.dset(mouse, "y", win.mouse.pos.y.newVal)
        i.dset(mouse, "click", win.mouse.mclick.mapIt(it.int.newVal).newVal)
        i.dset(mouse, "hold", win.mouse.mhold.mapIt(it.int.newVal).newVal)
        i.push mouse
    
    def.symbol("sleep") do (i: In):
        var vals = i.expect("int", "dict:window")
        vals[1].toFenster.sleep(vals[0].intVal)

    def.symbol("time") do (i: In):
        var vals = i.expect("dict:window")
        i.push vals[0].toFenster.time.newVal

    def.symbol("clear") do (i: In):
        var vals = i.expect("dict:window")
        vals[0].toFenster.clear()

    def.finalize("gui")
