identity = (val) -> return val
module.exports =
  _name: "combined"
  _v: 1
  mixins: [
    require("./watch")
    require("./computed")
  ]
  methods:
    $combined: (o) ->
      for name,v of o.value
        makeHiddenName = (name2) -> "__#{name}_#{name2}"
        createObj = (obj) ->
          obj.path = "#{o.path}.#{obj.name}"
          obj.parent = o.value
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
          @$watch.init createObj
            name: data
            value: v.data.call(@)
        else
          data = null
        getterFactory = (self, parent, prop, computed, data, normalize, parseProp) -> ->
          if prop and (propVal = self[prop])?
            obj = normalize(parseProp(propVal))
          else
            obj = {}
          if data
            for k,v of normalize(parent[data])
              obj[k] ?= v
          if computed
            for k,v of normalize(parent[computed])
              obj[k] ?= v
          return obj
        @$computed.init createObj
          name: makeHiddenName("combined")
          cbs: o.cbFactory.call(@,name)
          get: getterFactory(@, o.value, v.prop, computed, data, o.normalize || identity, o.parseProp || identity)
            



test module.exports, (merge) ->
  describe "ceri", ->
    describe "combined", ->
      el = null
      before ->
        el = makeEl merge 
          data: -> someProp: parentProp: "parentProp1"
          combinedTest: {}
      after -> el.remove()
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