{identity,noop} = require "./_helpers"
module.exports =
  _name: "combined"
  _v: 1
  mixins: [
    require("./watch")
    require("./computed")
  ]
  methods:
    $combined: (o) ->
      @$path.toNameAndParent(o)
      unless o.parent.hasOwnProperty(o.name)
        Object.defineProperty o.parent, o.name, __proto__:null, value: {}
      combinedParent = o.parent[o.name]
      Object.keys(o.value).forEach (name) =>
        v = o.value[name]
        makeHiddenName = (name2) -> "__#{name}_#{name2}"
        createObj = (obj) ->
          obj.path = "#{o.path}.#{obj.name}"
          obj.parent = combinedParent
          return obj
        if v.computed?
          computed = makeHiddenName("computed")
          @$computed.init createObj
            name: computed
            get: v.computed
        else
          computed = null
        if v.data?
          data = name
          @$watch.path createObj
            name: data
            value: v.data.call(@)
        else
          data = null 
        combined = makeHiddenName("combined")
        deferred = ->
          getterFactory = (parent, combined, prop, computed, data, normalize, parseProp) ->
            getter = ->
              if prop and (propVal = @[prop])?
                  obj = normalize(parseProp(propVal))
                else
                  obj = {}
              if computed
                for k,v of normalize(parent[computed])
                  obj[k] ?= v
              if data
                for k,v of normalize(parent[data])
                  obj[k] ?= v
              return obj
            return getter.bind(@)
          @$computed.init createObj
            name: combined
            cbs: o.cbFactory.call(@,name)
            get: getterFactory.call(@, combinedParent, combined, v.prop, computed, data, o.normalize || identity, o.parseProp || identity)

        if @$computed.__deferredInits
          Object.defineProperty combinedParent, combined, configurable: true, set: noop, get: noop
          @$computed.__deferredInits.push deferred
        else
          deferred.call(@)



test module.exports, {
  data: -> someProp: parentProp: "parentProp1"
  combinedTest: {}
}, (el) ->
  it "should work", (done) ->
    el.combinedTest =
      name:
        data: -> parentData: "parentData1"
        computed: -> parentComputed: "parentComputed1"
        prop: "someProp"
    el.$combined
      path: "combinedTest"
      value: el.combinedTest
      cbFactory: -> [(val) ->
        val.parentData.should.equal "parentData1"
        val.parentComputed.should.equal "parentComputed1"
        val.parentProp.should.equal "parentProp1"
        done()
        ]