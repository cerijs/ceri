module.exports =
  _name: "@tap"
  _v: 1
  _evLookup: 
    tap: (o) ->
      o.timeout = 300
      o.activate = ->
        el = @$parseElement.byString(o.el)
        cb = o.cb.bind(@,el)
        startTouchend = ->
          el.addEventListener "touchend", cb, o.capture
          setTimeout (->el.removeEventListener "touchend", cb), o.timeout
        el.addEventListener "touchstart", startTouchend, o.capture
        return o.deactivate = -> el.removeEventListener "touchstart", startTouchend
      return o