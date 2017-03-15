{isString,arrayize} = require("./_helpers")

module.exports =
  _name: "events"
  _v: 1
  _prio: 900
  _mergers: require("./_merger").copy source: "events"
  methods:
    "$once": (o) ->
      remover = null
      cb = o.cb
      o.cb = (e) ->
        if cb.call(@, e)
          remover() if remover?
      return remover = @$on(o)
    "$on": (o) ->
      o.el ?= @
      o.cb = o.cb.bind(@)
      o.el.addEventListener o.event, o.cb, o.useCapture
      remover = ->
        o.el.removeEventListener o.event, o.cb
        remover = null
      return remover
    "$emit": (o) ->
      o.el ?= @
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent o.name, false, false, o.detail
      o.el.dispatchEvent evt
  connectedCallback: ->
    if @_isFirstConnect
      for k,v of @events
        for fn in arrayize(v)
          fn = @[fn] if isString(fn)
          @addEventListener k, fn

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
