{arrayize, isString, isArray, isObject,clone, getID, concat} = require("./_helpers")
merger = require("./_merger")
arrayProto = Object.create(Array.prototype)
watchStr = "__watch__"
watchStr2 = "__watchChild__"
instancesStr = "__instances__"
for method in  ['push','pop','shift','unshift','splice','sort','reverse']
  arrayProto[method] = ->
    @$notify()
    Array.prototype[method].apply @, arguments
  ###fn = (method, cb) -> ->
    cb?.apply(@,arguments)
    @[watchStr].notify(@)
    return arrayProto[method].apply @, arguments
  switch method
    when 'push','unshift'
      arrayProto[method] = fn method, ->
        o = @[watchStr]
        o.init(arr: arguments, notify: o.notify)
    when 'splice'
      arrayProto[method] = fn method, ->
        o = @[watchStr]
        o.init(arr: arguments.slice(2), notify: o.notify)
    else
      arrayProto[method] = fn method###
module.exports =
  _name: "watch"
  _prio: 1000
  _v: 1
  _mergers: [
    merger.copy(source: "watch")
    merger.concat(source: "data")
  ]
  _rebind: "$watch"
  mixins: [
    require "./path"
  ]
  methods:
    $watch:
      __w: {}

      getObj: (o) ->
        if o.path? and (obj = @$watch.__w[o.path])?
          return obj
        return null

      setObj: (o) ->
        @$watch.__w[o.path] = o

      parseCbs: (o, prop) ->
        o[prop] = arrayize(o[prop]).map (cb) =>
          if isString(cb)
            cwarn !@[cb],"method ", cb, " not found"
            return @[cb]
          return cb

      parse: (obj,shouldClone) ->
        unless isObject(obj)
          obj = cbs: obj
        else if shouldClone
          obj = clone(obj)
        if not obj.__parsed__
          @$watch.parseCbs(obj, "cbs")
          unless obj.initial == false
            unless obj.initial
              obj.initial = obj.cbs.slice()
            else
              @$watch.parseCbs(obj, "initial")
          obj.__parsed__ = true
        return obj

      merge: (o1, o2) ->
        concat o1.cbs, o2.cbs
        if o2.initial
          if o1.initial
           concat o1.initial, o2.initial
          else
            o1.initial = o2.initial

      getConfig: (o) ->
        if not o.__configured__ and o.path? and (tmp = @watch?[o.path])?
          c = @$watch.parse(tmp, true)
          @$watch.merge(o,c)
          o.__configured__ = true

      init: (o) ->
        obj = @$watch.getObj(o)
        if obj?.__init__ # already initialized
          @$watch.merge(obj,o)
          obj.parent = o.parent if o.parent?
          if o.hasOwnProperty("value")
            oldVal = obj.value
            obj.value = o.value
          @$watch.processNewValue(obj, oldVal)
          return obj
        else # not initialized yet
          @$watch.getConfig(o)
          if obj # but object already saved
            @$watch.merge(obj, o) 
            return obj
          else
            @$watch.setObj(o)
            return o

      path: (o) ->
        if o.parentPath? and o.name?
          o.path = o.parentPath + "." + o.name
        cwarn !o.path?, "$watch.path requires path"
        @$path.toNameAndParent(o)
        @$watch.parse(o)
        unless o.parent # save cbs for later
          if (obj = @$watch.getObj(o))? # watch obj already saved
            @$watch.merge(obj, o)
            cwarn o.value?, "can't set #{o.value} on #{o.path} yet. Parent isn't setted yet"
            return
          else # save watch obj for later
            @$watch.setObj(o) 
        else # can be appended
          o = @$watch.init(o)
          unless o.__init__ # needs setup
            o.__init__ = true
            o.id = getID()
            o.instance = @
            o.value ?= o.parent[o.name]
            o.notify = (val = o.value, oldVal = o.value) ->
              for cb in o.cbs
                cb.call(o.instance, val, oldVal)
              return
            o.notify.owner = o
            @$watch.processNewValue(o)
          # triggering cbs
          if o.initial and o.value?
            for cb in o.initial
              cb.call(@,o.value)
            o.initial = false
        return o

      processNewValue: (o, oldVal) ->
        id = @_ceriID
        child = o.value
        parent = o.parent
        shouldSetup = not o.isComputed and 
          (not (desc = Object.getOwnPropertyDescriptor parent, o.name)? or 
          not desc.get)
        parentIsInstance = parent == @
        hasProto = child?.__proto__?
        isPrimitiv = not child? or isString(child) or not hasProto
        define = (getter, setter) ->
          Object.defineProperty o.parent, o.name,
            configurable: true
            enumerable: true
            get: getter
            set: setter
        setProto = (obj) ->
          if isArray(child)
            proto = arrayProto
          else
            proto = child.__proto__
          child.__proto__ = Object.create proto, obj
        if parentIsInstance # no sharing
          if shouldSetup # simple setup
            getter = ->
              if window.__ceriDeps? and not window.__ceriDeps[o.id]?
                o.cbs.push window.__ceriDeps(o.id).notify
              return o.value
            setter = (newVal) ->
              oldVal = o.value
              o.value = newVal
              # iterate over children
              @$watch.processNewValue(o,oldVal)
              o.notify(newVal, oldVal)
            define(getter, setter.bind(@))
          unless isPrimitiv # prepare saving children watchers
            unless child.$notify
              obj = {}
              obj[watchStr2] = value: {}
              obj["$notify"] = value: o.notify
              setProto(obj)
        else # sharing of watchers
          if isPrimitiv # save on parent
            if (tmp = parent[watchStr2])?
              tmp[o.name] ?= {}
              wrapper = tmp[o.name]
          else # save on prototype
            unless (wrapper = child[watchStr])?
              wrapper = {}
          if wrapper
            wrapper[id] = o
            unless wrapper[id]?
              wrapper[id] = o
            if shouldSetup
              cerror !wrapper, "error setting up watcher for #{o.name} on #{o.parent}"
              value = o.value
              getter =  ->
                if window.__ceriDeps? and 
                    (o = wrapper[window.__ceriActiveInstance._ceriID])? and
                    not window.__ceriDeps[o.id]?
                  o.cbs.push window.__ceriDeps(o.id).notify
                return value
              setter = (newVal) ->
                # iterate over children
                value = newVal
                for k, obj of wrapper
                  oldVal = obj.value
                  obj.value = newVal
                  obj.instance.$watch.processNewValue(obj,oldVal)
                  obj.notify(newVal, oldVal)
              define(getter, setter.bind(@))
          if hasProto and not child[watchStr]?
            obj = {}
            obj[watchStr] = value: wrapper
            obj[watchStr2] = value: {} unless isArray(child)
            obj["$notify"] = value: ->
              for k, obj of wrapper
                obj.instance.notify()
            setProto(obj)
          
        # remove reference from old value
        if oldVal? and 
            oldVal != child
          if (obj = oldVal[watchStr])?[id]?
            delete obj[id] 
          if (obj = oldVal[watchStr2])?
            for k,v of obj
              delete v[id] if v[id]?

        # wiring all cbs for all children
        if not isPrimitiv and not isArray(child) and not child._isCeri
          for own k, v of child
            @$watch.path(parent: child, name:k, value:v, parentPath: o.path)
          if isObject(oldVal) and not isArray(oldVal) and not child._isCeri
            watcher2 = child[watchStr2]
            for own k, v of oldVal
              if v != (newVal = child[k])
                notify = newVal?.$notify || watcher2?[k]?[id]?.notify
                notify?(newVal, oldVal)

  created: ->
    # make data responsive
    for fn in @data
      obj = fn.call(@)
      for k,v of obj
        @$watch.path(parent:@, name: k, value: v, path: k)


test module.exports, (merge) ->
  describe "ceri", ->
    describe "watch", ->
      el = el2 = null
      spy = (id) -> spy[id] ?= chai.spy()
      sharedObj = nested: "test40"
      getWatchObj = (el, name) -> el.$watch.__w[name]
      before (done) ->
        el = makeEl merge 
          data: ->
            someData: "test"
            someData2: "test10"
            someArray: ["test20"]
            someObj:
              someNestedProp: "test30"
            sharedObj: sharedObj
          watch:
            someData:
              initial: false 
              cbs: spy(1)
            someData2:  spy(2)
            someArray: spy(3)
            "someObj.someNestedProp": spy(5)
            sharedObj: spy(6)
            "sharedObj.nested": spy(6)
          created: ->
            @$watch.path path:"someData", cbs: spy(4)
        el2 = makeEl merge
          data: ->
            sharedObj: sharedObj
          watch:
            sharedObj: spy(7)
            "sharedObj.nested": spy(7)
        el.$nextTick done
      after -> 
        el.remove()
        el2.remove()
      it "should create data", ->
        should.exist el.someData
        el.someData.should.equal "test"
        el.someData2.should.equal "test10"
        el.someArray[0].should.equal "test20"
        el.someObj.someNestedProp.should.equal "test30"
      it "should work with initial", ->
        spy(1).should.not.have.been.called()
        spy(2).should.have.been.called.with "test10"
        spy(3).should.have.been.called.once()
        spy(4).should.have.been.called.with "test"
        spy(5).should.have.been.called.with "test30"
      it "should notify on change", ->
        el.someData = "test2"
        spy(1).should.have.been.called.with "test2", "test"
        spy(4).should.have.been.called.with "test2", "test"
      it "should work with arrays", ->
        spy(3).reset()
        el.someArray.push "test21"
        spy(3).should.have.been.called.once()
      it "should work with nested props", ->
        el.someObj.someNestedProp = "test31"
        spy(5).should.have.been.called.with "test31","test30"
      it "should work with nested shared objs", ->
        el.sharedObj.nested = "test40"
        #spy(6).should.have.been.called.twice
        #spy(7).should.have.been.called.twice
        spy(6).reset()
        spy(7).reset()
        el.sharedObj.nested = "test41"
        el2.sharedObj.nested.should.equal "test41"

        spy(6).should.have.been.called.with "test41","test40"
        spy(7).should.have.been.called.with "test41","test40"
      it "should work with shared objs", ->
        spy(6).reset()
        spy(7).reset()
        el.sharedObj = nested: "test42"
        spy(6).should.have.been.called.twice()
        spy(7).should.not.have.been.called()
      
      
      after -> el.remove()
