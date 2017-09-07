{isString,clone} = require("./_helpers")

getEvent = (el, event, throttle,stop, cb) -> el: el, event:event, stop: stop,prevent: !stop, notPrevented: true, cbs:[cb], throttle: throttle

dEl = document.documentElement
start = (o, name, name2, e) ->
  if e.changedTouches?
    e = e.changedTouches[0]
    isTouch = true
  o.start = x: e.clientX, y: e.clientY
  o.firstMove = true
  o.onStart?.call(@, o)
  o._moveRemover = @$on getEvent(dEl, name + "move", true, isTouch, move.bind(@,o))
  @$once getEvent(dEl, name + name2, false, isTouch, end.bind(@,o))

getDelta = (s, e) -> 
  x: e.clientX - s.x, y: e.clientY - s.y, start: s

move = (o, e) ->
  e = e.changedTouches[0] if e.changedTouches?
  o.secondMove = o.firstMove
  o.onFirstMove?.call(@, o, e) if o.firstMove
  o.onMove?.call(@, getDelta(o.start,e) , o, e)
  o.firstMove = false
end = (o, e) -> 
  o._moveRemover?()
  o._moveRemover = null
  if o.firstMove
    o.onClick?.call(@,o)
  else

    o.onEnd?.call(@, getDelta(o.start,e), o)
    o.onClick?.call(@,o) if o.secondMove



module.exports =
  _name: "draghandle"
  _v: 1
  mixins:[
    require("./events")
    require("./parseElement")
    require("./style")
  ]

  methods:
    $draghandle: (o) ->
      o.handle ?= document.createElement "div"
      o.activate = ->
        _el = @$parseElement.byString(o.el)
        unless o.wasActivated
          if o.initStyle?
            @$style.set(o.handle,o.initStyle)
          if o.style?
            @$computed.orWatch o.style, @$style.set.bind(@,o.handle)
          @$on getEvent o.handle, "touchstart", false, true, start.bind(@, o, "touch", "end")
          @$on getEvent o.handle, "mousedown", false, false, start.bind(@, o, "mouse", "up")
          @$path.resolveMultiple(o,["onStart","onFirstMove","onMove","onEnd","onClick"])
          
        _el.appendChild o.handle
        return ->
          _el.removeChild o.handle
      return @$parseActive(o)


  connectedCallback: ->
    if @_isFirstConnect and @draghandle
      for k,v of @draghandle
        v = clone(v)
        v.el ?= k
        @$draghandle(v)

test module.exports, {}, (el) ->
  it "should work", ->