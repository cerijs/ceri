{noop, isObject} = require("./_helpers")
module.exports =
  _name: "computed"
  _prio: 900
  _v: 1
  _mergers: require("./_merger").copy(source: "computed")
  _rebind: "$computed"
  mixins: [
    require("./watch")
  ]
  methods:
    $computed:
      __chain: []
      __deps: null
      init: (o) ->
        unless @$watch.getFromParent(o) # already initialized
          o.value = null
          o.set ?= noop
          o.dirty = true
          o.knownDeps = []
          @$watch.initWatch(o)
          o.this = @
          o.notify = ->
            o.dirty = true
            if o.cbs.length > 0
              oldVal = o.value
              newVal = o.parent[o.name]
              for cb in o.cbs
                cb.call o.this, newVal, oldVal
          o.isComputed = true
          @$watch.setOnParent o
          Object.defineProperty o.parent, o.name,
            get: ->
              if o.dirty
                c = o.this.$computed
                tmp = c.__deps
                c.__deps = o.knownDeps
                unless present = c.__chain.indexOf(o.notify) > -1
                  c.__chain.push o.notify
                o.value = o.get.call(o.this)
                o.dirty = false
                unless present
                  c.__chain.pop()
                c.__deps = tmp
              return o.value
            set: o.set
          if o.cbs.length > 0
            o.notify()
  created: ->
    for k,v of @computed
      v = {get: v} unless isObject(v)
      v.parent = @
      v.name = k
      v.path = k
      @$computed.init v
test module.exports, (merge) ->
  spy = chai.spy()
  spy2 = chai.spy()
  obj = merge {
    mixins: [require("./util")]
    data: -> someData: "test"
    computed:
      someData2: -> @someData
    watch:
      someData: spy2
      someData2: spy
  }
  el = makeEl(obj)
  describe "ceri", ->
    describe "computed", ->
      it "should compute", ->
        el.someData2.should.equal "test"
      it "should call spy on change", ->
        spy.should.have.been.called.once()
        el.someData = "test2"
        spy.should.have.been.called.with "test2", "test"
        spy2.should.have.been.called.with "test2", "test"
        el.someData2.should.equal "test2"
      after -> el.remove()
