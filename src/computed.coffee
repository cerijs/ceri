{noop, isObject, isFunction, clone, getID} = require("./_helpers")
window.__ceriDeps = null
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
      __deferredInits: []
      init: (o) ->
        @$watch.parse(o)
        o = @$watch.init(o) 
        if o # needs setup
          o.id = getID()
          o.deps = (id) ->
            o.deps[id] = true
            return o
          o.cDeps = []
          o.notify = ->
            o.dirty = true
            if o.cbs.length > 0
              oldVal = o.value
              newVal = o.parent[o.name]
              for cb in o.cbs
                cb(newVal, oldVal)
            for c in o.cDeps
              c.notify() unless c.dirty
          if o.set?
            o.set = o.set.bind(@)
          else
            o.set = noop
          o.get = o.get.bind(@)
          o.oldValue = null
          o.getter = ->
            if o.dirty # get all watcher dependecies
              o.dirty = false
              tmp = window.__ceriDeps
              window.__ceriDeps = o.deps
              o.oldValue = o.value
              o.value = o.get()
              @$watch.processNewValue(o)
              window.__ceriDeps = tmp
              # managing cyclic dependecies
              if o.oldValue != o.value
                for c in o.cDeps
                  if not c.dirty and o.deps[c.id]?
                    c.notify()

            if window.__ceriDeps? and not window.__ceriDeps[o.id]?
                o.cDeps.push window.__ceriDeps(o.id)
            return o.value
          o.getter = o.getter.bind(@)
          deferred = ->
            o.dirty = true
            Object.defineProperty o.parent, o.name,
              get: o.getter
              set: o.set
            # next tick, so all computed values are setup
            if o.cbs.length > 0
              @$nextTick o.notify
            else # search for descendand deps
              @$nextTick ->
                for k in Object.keys(@$watch.__w)
                  if k.indexOf(o.path) > -1
                    o.parent[o.name]
                    break
          if @$computed.__deferredInits and not o.noWait
            @$computed.__deferredInits.push deferred
          else
            deferred.call(@)
      getNotifyCb: (o) ->
        cwarn !o.path?, "getNotifyCb requires a path"
        if (o = @$watch.getObj(o))? and o.notify?
          return o.notify
        cwarn true, "couldn't get notify cb for computed ", o.path
        return noop

  created: ->
    for k,v of @computed
      if isObject(v)
        v = clone(v)
      else
        v = {get: v} 
      v.parent = @
      v.name = k
      v.path = k
      @$computed.init v
  connectedCallback: -> @$nextTick ->
    arr = @$computed.__deferredInits
    @$computed.__deferredInits = false
    for deferred in arr
      deferred.call(@)
test module.exports, (merge) ->
  spy = chai.spy()
  spy2 = chai.spy()
  obj = merge {
    mixins: [require("./util")]
    data: -> someData: "test"
    computed:
      someData2: -> @someData
      someData3: -> @someData2
      someData4: -> @someData + @someData2
      someData5: ->
        @someData6
      someData6: ->
        if @someData5
          return 2
        return 1
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
      it "should work with computed dependecies", ->
        el.someData = "test3"
        el.someData2.should.equal "test3"
        el.someData3.should.equal "test3"
      it "should work with combined dependecies", ->
        el.someData = "test4"
        el.someData4.should.equal "test4test4"
      it "should work with cyclic dependecies", ->
        el.someData6.should.equal 1
        el.someData5.should.equal 1
        el.someData6.should.equal 2
      after -> el.remove()
