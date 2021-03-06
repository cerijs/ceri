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
    if ~(i = o.cbs.indexOf(cb))
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
    require "./parseFunction"
  ]
  _evLookup: {}
  methods:
    $once: (o) ->
      o.once = true
      return @$on(o)
    $on: (o) ->
      o._cbs = cbs = []
      if o.toggle
        o.toggle = o.value unless isString(o.toggle)
        obj = @$path.toNameAndParent(path:o.toggle)
        cbs.push -> 
          obj.parent[obj.name] = !obj.parent[obj.name]
      else
        for str in arrayize(o.cbs)
          @$parseFunction str, (fn, oldFn) -> 
            if oldFn and ~(index = cbs.indexOf(oldFn))
              cbs.splice index, 1
            cbs.push fn if fn and isFunction(fn)
      o.cb = (el, e) ->
        return if o.self and e.target != el
        return if o.notPrevented and e.defaultPrevented
        return if o.keyCode and not ~o.keyCode.indexOf(e.keyCode)
        if o.outside and e.target?
          target = e.target
          while target?
            if target == @
              return
            target = target.parentElement
        if o.inside and e.target?
          target = e.target
          isInside = false
          while target?
            if target == el
              isInside = true
              break
            target = target.parentElement
          return unless isInside
        if o.defer?.delay
          if o.defer.canceled
            clearTimeout o.defer.timeout
            o.defer.canceled = false
          delay = (isString(o.defer.delay) and @$path.getValue(o.defer.delay)) or o.defer.delay
          if delay > 1
            if o.defer.cancel
              o.defer.canceler = []
              for ev in arrayize(o.defer.cancel)
                o.defer.canceler.push @$once el:o.el, event: ev, cbs: ->
                  o.defer.canceled = true
            o.defer.timeout = setTimeout (=>
              if o.defer.canceler
                for deactivate in o.defer.canceler
                  deactivate()
                o.defer.canceler = null
              unless o.defer.canceled
                for ocb in o._cbs
                  ocb.call @, e
              o.defer.canceled = false
              ), delay
        else
          for ocb in o._cbs
            ocb.call @, e
        e.preventDefault() if o.prevent
        e.stopPropagation() if o.stop
        o.deactivate() if o.once
      if @_evLookup[o.event]?
        o = @_evLookup[o.event].call(@,o)
      else
        o.activate = ->
          el = @$parseElement.byString(o.el)
          _cb = o.cb.bind(@,el)
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
  el = null
  spy = sinon.spy()
  before (done) ->
    el = makeEl merge 
      events:
        someEvent: (e) -> spy(e.detail)
    el.$nextTick done
  after -> el.remove()
  it "should work", ->
    el.$emit name: "someEvent", detail: "test"
    spy.should.have.been.calledWith "test"
