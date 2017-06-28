{noop, isString, isArray, isObject, isFunction, clone, getID} = require("./_helpers")
window.__ceriDeps = null
id = 0
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
      init: (o) ->
        unless o.path # create anonymous computed value
          o.id = getID()
          o.path = "__computed."+o.id
          o.parent = @__computed
          o.name = o.id
        @$watch.parse(o)
        o = @$watch.init(o) 
        unless o.__init__ # needs setup
          o.__init__ = true
          o.id ?= getID()
          o.isComputed = true
          o.deps = (id) ->
            o.deps[id] = true
            return o
          o.cDeps = []
          o.instance = @
          o.notify = ->
            o.dirty = true
            if o.cbs.length > 0
              oldVal = o.value
              newVal = o.parent[o.name]
              instance = o.instance
              for cb in o.cbs
                cb.call(instance, newVal, oldVal)
            for c in o.cDeps
              c.notify() unless c.dirty
          o.notify.owner = o
          if o.set?
            o.setter = o.set.bind(@)
          else
            o.setter = noop
          o.get = o.get.bind(@)
          o.oldValue = null
          o.getter = ->
            if o.dirty # get all watcher dependecies
              o.dirty = false
              tmp = window.__ceriDeps
              tmp2 = window.__ceriActiveInstance
              window.__ceriDeps = o.deps
              window.__ceriActiveInstance = @
              o.oldValue = o.value
              o.value = o.get()
              
              window.__ceriDeps = tmp
              window.__ceriActiveInstance = tmp2
              @$watch.processNewValue(o,o.oldValue)
              # managing cyclic dependecies
              if !isObject(o.value) and !isArray(o.value) and o.oldValue != o.value
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
              set: o.setter
            # next tick, so all computed values are setup
            if o.cbs.length > 0
              @$nextTick o.notify
            else # search for descendand deps
              @$nextTick ->
                for k in Object.keys(@$watch.__w)
                  if k.indexOf(o.path) > -1 and k != o.path
                    o.parent[o.name]
                    break
          if @$computed.__deferredInits and not o.noWait
            @$computed.__deferredInits.push deferred
          else
            deferred.call(@)
        return o
      getNotifyCb: (o) ->
        cwarn !o.path?, "getNotifyCb requires a path"
        if (o = @$watch.getObj(o))? and o.notify?
          return o.notify
        cwarn true, "couldn't get notify cb for computed ", o.path
        return noop
      orWatch: (val, cbs) ->
        if isString(val)
          return @$watch.path path:val, cbs: cbs
        else
          return @$computed.init get: val, cbs: cbs
      setup: (obj, parent = @) ->
        for k,v of obj
          if isObject(v)
            v = clone(v)
          else
            v = {get: v} 
          v.parent = parent
          v.name = k
          v.path = k
          @$computed.init v
  created: ->
    @$computed.__deferredInits = []
    @__computed = {} # to hold all anonymous computed values
    @$computed.setup(@computed)
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
      someData7: -> @someData
      someData8: -> @someData2 + @someData7
      someData9: -> @someData3
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
      it "should work with branched dependecies", ->
        el.someData = "test5"
        el.someData8.should.equal "test5test5"
        el.someData = "test6"
        el.someData8.should.equal "test6test6"
      it "should work with deep dependencies", ->
        el.someData = "test7"
        el.someData9.should.equal "test7"
        el.someData = "test8"
        el.someData9.should.equal "test8"
      after -> el.remove()
