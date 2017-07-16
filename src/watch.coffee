{arrayize, isString, isArray, isObject,clone, getID, concat} = require("./_helpers")
merger = require("./_merger")
watchStr = "__watch__"
instancesStr = "__instances__"

module.exports =
  _name: "watch"
  _prio: 1000
  _v: 1
  _mergers: [
    merger.copy(source: "watch", target: "_watch")
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
        if o.path? and (obj = @$watch.__w[o.path] or @__parent?.$watch.__w[o.path])?
          return obj
        return null

      setObj: (o) ->
        o = (w = @$watch).sharedInit(o)
        w.__w[o.path] = o if o.path?
        return o

      notify: (path) ->
        unless (o = @$watch.getObj(path:path))
          unless (o = @__parent?.$watch.getObj(path:path))
            cwarn(true, "watch: couldn't notify #{path}")
            return  
        o.notify(o.value)
      
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
        if o2.parent?
          o1.parent = o2.parent
          @$watch.setupParent(o1) if o1.__init__
        if o2.hasOwnProperty("value") and o2.value != o1.value
          o1.parent[o1.name] = o2.value
      getConfig: (o) ->
        if not o.__configured__ and o.path? and (tmp = @_watch?[o.path])?
          w = @$watch
          c = w.parse(tmp, true)
          w.merge(o,c)
          o.__configured__ = true

      init: (o) ->
        w = @$watch
        obj = w.getObj(o)
        if obj?.__init__ # already initialized
          w.merge(obj,o)
          return obj
        else # not initialized yet
          w.getConfig(o)
          if obj # but object already saved
            w.merge(obj, o) 
            return w.sharedInit(obj)
          else
            return w.setObj(o)
             
      sharedInit: (o) ->
        unless o.__sInit__
          o.__sInit__ = true
          o.cDeps = []
          o._taints = null
          o.id = getID()
          o.instance = @
          o.checkComputed = ->
            if (not (cai = window.__ceriActiveInstance)? or cai == o.instance or cai.__parent == o.instance) and 
                ((cd = window.__ceriDeps)? and not cd[o.id]?)
              o.cDeps.push (cd(o))
              o.nullTaints()
        return o
      setupParent: (o) ->
        parent = o.parent
        name = o.name
        if o.oldParent != parent
          if (oldArr = o.watchArr)?
            if ~(i = oldArr.indexOf(o))
              oldArr.splice(i,1)
            delete o.watchArr
          o.oldParent = parent
          if not (desc = Object.getOwnPropertyDescriptor parent, name)? or not desc.get
            Object.defineProperty parent, name,
              configurable: true
              enumerable: true
              get: ->
                for obj in wrapper.objs
                  obj.checkComputed()
                return wrapper.value
              set: (newVal) ->
                wrapper.value = newVal
                for obj in wrapper.objs
                  obj.oldVal = obj.value
                  obj.value = newVal
                  # iterate over children
                  obj.instance.$watch.processNewValue(obj)
                  obj.notify(newVal, obj.oldVal)
        unless o.watchArr
          unless parent._isCeri
            unless (wrapper = parent[watchStr])?
              wrapper = {}
              obj = {}
              obj[watchStr] = value: wrapper
              parent.__proto__ = Object.create parent.__proto__, obj
            wrapper = wrapper[name] ?= {
                objs: []
                value: o.value
              }
            wrapper.objs.push o
          else
            wrapper = 
              objs: [o]
              value: o.value
          o.watchArr = wrapper.objs
        return o
      path: (o) ->
        if o.parentPath? and o.name?
          o.path = o.parentPath + "." + o.name
        #cwarn !o.path?, "$watch.path requires path"
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
            o.value ?= o.parent[o.name]
            
            o.nullTaints = -> o._taints = null
            o.notify = (val, oldVal) ->
              unless (taints = o._taints)?
                taints = o._taints = o.cDeps.reduce(((h, c) -> c.getTaints(h,true)
                ), _taints: [])._taints
              for cb in taints.map((taint) => taint())
                cb()
              for cb in o.cbs
                cb.call(o.instance, val, oldVal, o)
              return
            @$watch.setupParent(o)
            @$watch.processNewValue(o)
          # triggering cbs
          if o.initial 
            if o.value?
              for cb in o.initial
                cb.call(@,o.value)
            else if o.dirty
              o.notify(o.value)
            o.initial = false
        return o

      processNewValue: (o) ->
        child = o.value
        parent = o.parent
        isValidObj = (obj) -> obj? and isObject(obj) and not isArray(obj) and not obj?._isCeri
          
        # wiring all cbs for all children
        if isValidObj(child)
          for own k, v of child
            @$watch.path(parent: child, name:k, value:v, parentPath: o.path)
          if o.oldVal and isValidObj(o.oldVal) # detect deleted props
            for own k, v of o.oldVal
              unless child.hasOwnProperty(k)
                if (obj = @$watch.getObj(path: o.path+"."+k))?
                  obj.notify(null,v)

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
      spy = (id) -> spy[id] ?= sinon.spy()
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
        spy(1).should.not.have.been.called
        spy(2).should.have.been.calledWith "test10"
        spy(3).should.have.been.calledOnce
        spy(4).should.have.been.calledWith "test"
        spy(5).should.have.been.calledWith "test30"
      it "should notify on change", ->
        el.someData = "test2"
        spy(1).should.have.been.calledWith "test2", "test"
        spy(4).should.have.been.calledWith "test2", "test"
      it "should work with nested props", ->
        el.someObj.someNestedProp = "test31"
        spy(5).should.have.been.calledWith "test31","test30"
      it "should work with nested shared objs", ->
        spy(6).reset()
        spy(7).reset()
        el.sharedObj.nested = "test41"
        el2.sharedObj.nested.should.equal "test41"
        spy(6).should.have.been.calledWith "test41","test40"
        spy(7).should.have.been.calledWith "test41","test40"
      it "should work with shared objs", ->
        spy(6).reset()
        spy(7).reset()
        el.sharedObj = nested: "test42"
        spy(6).should.have.been.calledTwice
        spy(7).should.not.have.been.called
      
      
      after -> el.remove()
