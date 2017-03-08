{arrayize, isString, isArray, isObject,clone, getID} = require("./_helpers")
merger = require("./_merger")
arrayProto = Object.create(Array.prototype)
watchStr = "__watch__"
for method in  ['push','pop','shift','unshift','splice','sort','reverse']
  arrayProto[method] = ->
    @[watchStr].notify()
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
        if (obj = o.value?[watchStr])?
          @$watch.setObj(obj)
          return obj
        else if o.path? and (obj = @$watch.__w[o.path])?
          return obj
        return null
      setObj: (o) ->
        @$watch.__w[o.path] = o
      processNewValue: (o) ->
        child = o.value
        if child?.__proto__
          obj = {}
          obj[watchStr] = value: o
          if isArray(child)
            proto = arrayProto
          else
            proto = child.__proto__
            if isObject(child) and not child._isCeri
              for own k,v of child
                @$watch.path(parent: child, name:k, value: v, parentPath: o.path)
          child.__proto__ = Object.create proto, obj
          
      path: (o) ->
        if o.parentPath? and o.name?
          o.path = o.parentPath + "." + o.name
        cwarn !o.path?, "$watch.path requires path"
        @$path.toNameAndParent(o)
        @$watch.parse(o)
        unless o.parent # save cbs for later
          if (obj = @$watch.getObj(o))? # watch obj already saved
            for cb in o.cbs
              obj.cbs.push cb
            cwarn o.value?, "can't set #{o.value} on #{o.path} yet. Parent isn't setted yet"
            return
          else # save watch obj for later
            @$watch.setObj(o) 
        else # can be appended
          o = @$watch.init(o)
          if o # needs setup
            o.id = getID()
            o.notify = (val, oldVal) ->
              for cb in o.cbs
                try
                  cb(val, oldVal)
              return
            getter = ->
              if window.__ceriDeps? and not window.__ceriDeps[o.id]?
                o.cbs.push window.__ceriDeps(o.id).notify
              return o.value
            setter = (newVal) ->
              oldVal = o.value
              o.value = newVal
              # iterate over children
              @$watch.processNewValue(o)
              o.notify(newVal, oldVal)
            
            if o.initial
              if o.value?
                initVal = o.value
                delete o.value
              else
                initVal = o.parent[o.name]
            else
              o.value ?= o.parent[o.name]

            Object.defineProperty o.parent, o.name,
              get: getter.bind(@)
              set: setter.bind(@)
            
            # triggering cbs
            o.parent[o.name] = initVal if o.initial
            
      parse: (obj,shouldClone) ->
        unless isObject(obj)
          obj = cbs: obj
        else if shouldClone
          obj = clone(obj)
        unless obj.__parsed__
          obj.cbs = arrayize(obj.cbs).map (cb) =>
            if isString(cb)
              cwarn !@[cb],"method ", cb, " not found"
              return @[cb].bind(@)
            return cb.bind(@)
          obj.initial ?= true
          obj.__parsed__ = true
        return obj
      init: (o) ->
        obj = @$watch.getObj(o)
        if obj?.__init__ # already initialized
          for cb in o.cbs
            obj.cbs.push cb
          if o.value?
            if o.parent[o.name] != o.value
              o.parent[o.name] = o.value
          else if o.initial
            val = o.parent[o.name]
            for cb in o.cbs
              cb(val)
        else # not initialized yet
          o.__init__ = true
          if obj # but object already saved
            o.cbs = obj.cbs.concat(o.cbs)
          w = @$watch.parse(@watch[o.path],true)
          o.cbs = o.cbs.concat(w.cbs)
          @$watch.setObj(o)
          return o
        return false
        

  created: ->
    # make data responsive
    for fn in @data
      obj = fn.call(@)
      for k,v of obj
        @$watch.path(parent:@, name: k, value: v, path: k)


test module.exports, (merge) ->
  describe "ceri", ->
    describe "watch", ->
      el = null
      spy = chai.spy()
      spy2 = chai.spy()
      spy3 = chai.spy()
      spy4 = chai.spy()
      spy5 = chai.spy()
      before ->
        el = makeEl merge 
          data: ->
            someData: "test"
            someData2: "test10"
            someArray: ["test20"]
            someObj:
              someNestedProp: "test30"
          watch:
            someData:
              initial: false
              cbs: spy
            someData2: spy2
            someArray: spy3
            "someObj.someNestedProp": spy5
    created: ->
      @$watch.path path:"someData", cbs: spy4
      after -> el.remove()
      it "should create data", ->
        should.exist el.someData
        el.someData.should.equal "test"
        el.someData2.should.equal "test10"
        el.someArray[0].should.equal "test20"
        el.someObj.someNestedProp.should.equal "test30"
      it "should call spy on init", ->
        spy2.should.have.been.called.with "test10"
        spy3.should.have.been.called.once()
        spy4.should.have.been.called.with "test"
        spy5.should.have.been.called.with "test30"
      it "should call spy on change", ->
        spy.should.not.have.been.called()
        el.someData = "test2"
        spy.should.have.been.called.with "test2", "test"
        spy4.should.have.been.called.with "test2", "test"
      it "should work with arrays", ->
        el.someArray.push "test21"
        spy3.should.have.been.called.twice()
      it "should work with nested props", ->
        el.someObj.someNestedProp = "test31"
        spy5.should.have.been.called.with "test31","test30"
      after -> el.remove()
