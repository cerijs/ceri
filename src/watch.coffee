{arrayize, isString, isArray, isObject} = require("./_helpers")
merger = require("./_merger")
arrayProto = Object.create(Array.prototype)
watchStr = "__watch__"
for method in  ['push','pop','shift','unshift','splice','sort','reverse']
  fn = (method, cb) -> ->
    cb?.apply(@,arguments)
    @[watchStr].notify(@)
    return arrayProto.__proto__[method].apply @, arguments
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
      arrayProto[method] = fn method

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
      init: (o) ->
        init = @$watch.init
        if o.arr and o.notify
          o.init = init
          Object.defineProperty o.arr, watchStr, value: {init: init, notify: o.notify}
          o.arr.__proto__ = arrayProto
          for val in o.arr
            if isArray(val)
              init(arr: val, notify: o.notify)
            else if isObject(val)
              for own k,v of val
                init(parent: val, name:k, value: v)
        else
          if o.parentPath?
            o.path = o.parentPath + "." + o.name
          if @$watch.getFromParent(o) # already initialized
            @$path.setValue(o)
          else
            return unless o.name and o.parent
            @$path.toValue(o) unless o.value?
            o.id = Math.random()
            @$watch.initWatch(o)
            o.this = @
            o.notify = ->
              for cb in o.cbs
                cb.apply(o.this,arguments)
            @$watch.setOnParent o
            Object.defineProperty o.parent, o.name,
              get: ->
                if o.this.$computed?.__deps?.indexOf(o.id) == -1
                  o.this.$computed.__deps.push o.id
                  for cb in o.this.$computed.__chain
                    o.cbs.push cb unless o.cbs.indexOf(cb) > -1
                return o.value
              set: (newVal) ->
                oldVal = o.value
                o.value = newVal
                o.notify(newVal, oldVal)
            for cb in o.initial
              cb(o.value)
            # iterate over children
            if isArray(o.value)
              init(arr: o.value, notify: o.notify)
            else if isObject(o.value)
              for own k,v of o.value
                init(parent: o.value, name:k, value: v, parentPath: o.path)
      initWatch: (o) ->
        if o.cbs? and o.initial
          o.initial = o.cbs.slice(0)
        o.cbs ?= []
        o.initial ?= []
        if o.path and w = @watch[o.path]
          w = @$watch.parse(w)
          o.cbs = o.cbs.concat(w.cbs)
          if w.initial
            o.initial = o.initial.concat(w.cbs)
      parse: (obj) ->
        unless isObject(obj)
          obj = initial: true, cbs: obj
        unless obj.__parsed__
          obj.initial ?= true
          obj.cbs = arrayize(obj.cbs).map (cb) ->
            if isString(cb)
              return @[cb]
            return cb
          obj.__parsed__ = true
        return obj
      path: (watch) ->
        if (o = @$watch.getFromParent(watch)) && o != null
          @$watch.parse(watch)
          if watch.initial
            @$path.toValue(o)
          for cb in watch.cbs
            o.cbs.push cb
            cb(o.value) if watch.initial
      getFromParent: (o) ->
        @$path.toNameAndParent(o)
        if o.parent?.hasOwnProperty(watchStr) and o.name? and o.parent[watchStr][o.name]?
          return o.parent[watchStr][o.name]
        return null

      setOnParent: (o) ->
        unless o.parent.hasOwnProperty(watchStr)
          Object.defineProperty o.parent, watchStr, value: {}
        o.parent[watchStr][o.name] = o
  created: ->
    # make data responsive
    for fn in @data
      obj = fn.call(@)
      for k,v of obj
        @$watch.init.call(@,parent:@, name: k, value: v, path: k)


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
