{isString,isFunction,isArray,arrayize,noop,clone} = require("./_helpers")
module.exports =
  _name: "events"
  _v: 1
  _prio: 900
  _mergers: [
    require("./_merger").copy source: "events"
    require("./_merger").copy(source: "_evLookup")
    ]
  mixins: [
    require "./computed"
  ]
  _evLookup: {}
  methods:
    "$once": (o) ->
      o.once = true
      return @$on(o)
    "$on": (o) ->
      o.el ?= @
      cbs = []
      for fn in arrayize(o.cbs)
        fn = @[fn] if isString(fn)
        cbs.push fn
      o._cbs = cbs
      if @_evLookup[o.event]?
        {adder,remover} = @_evLookup[o.event].call(@,o)
      else
        if o.toggle
          obj = @$path.toNameAndParent(path:o.toggle)
          cb = -> obj.parent[obj.name] = !obj.parent[obj.name]
        else
          cb = (e) ->
            return if o.self and e.target != o.el
            return if o.notPrevented and e.defaultPrevented
            return if o.keyCode and o.keyCode.indexOf(e.keyCode) == -1
            if o.outside
              target = e.target
              while target?
                if target == @
                  return
                target = target.parentElement
            for ocb in o._cbs
              ocb.apply @, arguments
            e.preventDefault() if o.prevent
            e.stopPropagation() if o.stop
            remover() if o.once
        remover = noop
        cb = cb.bind(@)
        adder = ->
          if isString(o.el) 
            el = if o.el == "this" then @ else @[o.el] 
          else 
            el = o.el
          el.addEventListener o.event, cb, o.capture
          remover = ->
            el.removeEventListener o.event, cb
            remover = noop
          @__eventsToDestroy.push remover if o.destroy
          return
      if o.active
        @$computed.orWatch o.active, (val) ->
          if val
            if o.delay
              @$nextTick adder
            else
              adder.call(@)
          else
            remover()
      else
        return adder.call(@)
    "$emit": (o) ->
      o.el ?= @
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent o.name, false, false, o.detail
      o.el.dispatchEvent evt
  connectedCallback: ->
    if @_isFirstConnect
      @__eventsToDestroy = []
      for k,v of @events
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

        
  destroy: ->
    for cb in @__eventsToDestroy
      cb()

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
