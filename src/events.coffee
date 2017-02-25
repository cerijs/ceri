{isString,arrayize} = require("./_helpers")

module.exports =
  _name: "events"
  _v: 1
  _prio: 900
  _mergers: require("./_merger").copy source: "events"
  methods:
    "$emit": (el, name, options) ->
      if isString(el)
        options = name
        name = el
        el = @
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent name, false, false, options
      el.dispatchEvent evt
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
      before ->
        el = makeEl merge 
          events:
            someEvent: (e) -> spy(e.detail)
      after -> el.remove()
      it "should work", ->
        el.$emit "someEvent","test"
        spy.should.have.been.called.with "test"
