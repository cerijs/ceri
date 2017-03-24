{isString,isFunction,isArray,arrayize,noop,clone} = require("./_helpers")
rAF = requestAnimationFrame
cAF = cancelAnimationFrame
listener = (o,e) ->
  cAF(o.lastRequest)
  o.lastRequest = rAF ->
    for cb in o.cbs
      cb(e)
throttled = (el, event, cb) ->
  unless (o = el.__ceriEventListener?[event])?
    el.__ceriEventListener ?= {}
    o = el.__ceriEventListener[event] = {}
    o.lastRequest = null
    o.cbs = [cb]
    o.listener = listener.bind(null,o)
  else
    o.cbs.push cb
  if o.cbs.length == 1
    el.addEventListener event, o.listener
  return ->
    if (i = o.cbs.indexOf(cb)) > -1
      o.cbs.splice(i,1)
      if o.cbs.length == 0
        el.removeEventListener event, o.listener
module.exports =
  _name: "events"
  _v: 1
  _prio: 700
  _mergers: [
    require("./_merger").concat source: "events"
    require("./_merger").copy source: "_evLookup"
    ]
  mixins: [
    require "./computed"
    require "./parseElement"
    require "./parseActive"
  ]
  _evLookup: {}
  methods:
    $once: (o) ->
      o.once = true
      return @$on(o)
    $on: (o) ->
      cbs = []
      for fn in arrayize(o.cbs)
        fn = @[fn] if isString(fn)
        cbs.push fn
      o._cbs = cbs
      if @_evLookup[o.event]?
        o = @_evLookup[o.event].call(@,o)
      else
        if o.toggle
          o.toggle = o.value unless isString(o.toggle)
          obj = @$path.toNameAndParent(path:o.toggle)
          cb = ->
            obj.parent[obj.name] = !obj.parent[obj.name]
        else
          cb = (el, e) ->
            return if o.self and e.target != el
            return if o.notPrevented and e.defaultPrevented
            return if o.keyCode and o.keyCode.indexOf(e.keyCode) == -1
            if o.outside
              target = e.target
              while target?
                if target == @
                  return
                target = target.parentElement
            for ocb in o._cbs
              ocb.call @, e
            e.preventDefault() if o.prevent
            e.stopPropagation() if o.stop
            o.deactivate() if o.once
        
        o.activate = ->
          el = @$parseElement.byString(o.el)
          _cb = cb.bind(@,el)
          if o.throttled
            return o.deactivate = throttled(el, o.event, _cb)
          else
            el.addEventListener o.event, _cb, o.capture
            return o.deactivate = -> el.removeEventListener o.event, _cb
      return @$parseActive(o)
    $emit: (o) ->
      o.el ?= @
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent o.name, false, false, o.detail
      o.el.dispatchEvent evt
  connectedCallback: ->
    if @_isFirstConnect
      for events in @events
        for k,v of events
          if v.cbs?
            o = clone(v)
            o.event = k
            @$on o
          else if (isString(v) or isFunction(v) or isArray(v))
            @$on cbs:v, event: k
          else
            for el,v2 of v
              o = clone(v2)
              o.el ?= el
              o.event = k
              @$on o

test module.exports, (merge) ->
  describe "ceri", ->
    describe "events", ->
      el = null
      spy = chai.spy()
      before (done) ->
        el = makeEl merge 
          events:
            someEvent: (e) -> spy(e.detail)
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
        el.$emit name: "someEvent", detail: "test"
        spy.should.have.been.called.with "test"
