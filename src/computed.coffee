{noop, isString, isArray, isObject, isFunction, clone, getID,assign} = require("./_helpers")
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
        if o.parentPath? and o.name?
          o.path = o.parentPath + "." + o.name
        unless o.path # create anonymous computed value
          o.id = getID()
          o.path = "__computed."+o.id
          o.parent = @__computed
          o.name = o.id
        o.parent ?= @
        o.name ?= o.path
        @$watch.parse(o)
        o = @$watch.init(o) 
        unless o.__init__ # needs setup
          o.__init__ = true
          o.isComputed = true
          o.deps = (obj) ->
            o.deps[obj.id] = true
            o.ascs.push obj
            return o
          o.ascs = []
          o.nullTaints = ->
            for obj in o.ascs
              obj.nullTaints() if o != obj and obj._taints
            o._taints = null
          o.getTaints = (hash) ->
            if !(taints = o._taints)?
              taints = o._taints = o.cDeps.reduce(((h, c) ->
                unless c._gettingTaints
                  c._gettingTaints = true
                  h = c.getTaints(h)
                  c._gettingTaints = false
                  return h
                else
                  unless h[c.id]
                    h[c.id] = true
                    h._taints.push c.taint
                  return h
                ), _taints: [o.taint])._taints
            if hash?
              tmp = hash._taints
              for t in taints
                unless hash[t.id]
                  hash[t.id] = true
                  tmp.push t
              return hash
            else
              return taints
          o.instance = @
          o.taint = ->
            o.dirty = true
            return ->
              if o.cbs.length > 0
                instance = o.instance
                oldVal = o.value
                newVal = o.parent[o.name]
                for cb in o.cbs
                  cb.call(instance, newVal, oldVal, o)
          o.taint.id = o.id
          o.notify = ->
            for cb in o.getTaints().map((taint) => taint())
              cb()
          o.notify.owner = o
          if o.set?
            o.setter = o.set.bind(@)
          else
            o.setter = noop
          o.get = o.get.bind(@)
          o.oldVal = null
          o.getter = ->
            if o.dirty # get all watcher dependecies
              inst = o.instance
              o.dirty = false
              tmp = window.__ceriDeps
              tmp2 = window.__ceriActiveInstance
              window.__ceriDeps = o.deps
              window.__ceriActiveInstance = if o.master then null else inst
              o.oldVal = o.value
              o.value = o.get()
              window.__ceriDeps = tmp
              window.__ceriActiveInstance = tmp2
              # managing cyclic dependecies
              if !isObject(o.value) and !isArray(o.value) and o.oldVal != o.value
                for c in o.cDeps
                  if not c.dirty and o.deps[c.id]?
                    c.notify()
              inst.$watch.processNewValue(o)
            
            o.checkComputed()
            return o.value
          deferred = ->
            Object.defineProperty o.parent, o.name,
              get: o.getter
              set: o.setter
            
            # next tick, so all computed values are setup
            if o.cbs.length > 0
              @$nextTick o.notify
            else 
              o.dirty = true
              # search for descendand deps
              for k,v of @$watch.__w
                if ~k.indexOf(o.path) and k != o.path
                  o.cbs.push noop
                  @$nextTick o.notify
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
      parseAndInit: (obj, options) ->
        if isObject(obj)
          obj = clone(obj)
        else
          obj = {get: obj}
        @$computed.init assign(obj,options)
      setup: (obj, parent = @) ->
        for k,v of obj
          @$computed.parseAndInit v, {parent:parent, name:k, path:k}
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
  spy = sinon.spy()
  spy2 = sinon.spy()
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
  it "should compute", ->
    el.someData2.should.equal "test"
  it "should call spy on change", ->
    spy.should.have.been.calledOnce
    el.someData = "test2"
    spy.should.have.been.calledWith "test2", "test"
    spy2.should.have.been.calledWith "test2", "test"
    el.someData2.should.equal "test2"
  it "should work with computed dependecies", ->
    el.someData = "test3"
    el.someData2.should.equal "test3"
    el.someData3.should.equal "test3"
    el.someData = "test33"
    el.someData3.should.equal "test33"
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
