{isString} = require("./_helpers")
module.exports =
  _name: "class"
  _v: 1
  _rebind: "$class"
  _mergers: require("./_merger").copy(source: "initClass")
  methods:
    $class:
      strToObj: (str) ->
        result = {}
        if str?
          for cls in str.split(" ")
            result[cls] = true
        return result
      objToStr: (obj) ->
        result = []
        for k,v of obj
          result.push k if v
        return result.join " "
      setStr: (el, str) -> 
        el.className = str
      set: (el, obj) ->
        unless obj?
          obj = el
          el = @
        @$class.setStr(el,@$class.objToStr(obj))
  connectedCallback: ->
    if @_isFirstConnect and @initClass?
      if isString(@initClass)
        @$class.setStr @, @initClass
      else
        for k,v of @initClass
          if k == "this"
            @$class.setStr @, v
          else
            @$class.setStr @[k], v
test module.exports, (merge) ->
  describe "ceri", ->
    describe "class", ->
      el = null
      before ->
        el = makeEl merge {}
      after -> el.remove()
      it "should convert class string to obj", ->
        obj = el.$class.strToObj("test test2")
        obj.test.should.be.true
        obj.test2.should.be.true
      it "should convert obj to class string", ->
        el.$class.objToStr({test:true,test2:true,test3:false})
        .should.equal "test test2"
      it "should set class string on element", ->
        el.$class.setStr(el, "test test2")
        el.should.have.attr "class", "test test2"
      it "should set class obj on element", ->
        el.$class.set({test:true,test2:true,test3:false})
        el.should.have.attr "class", "test test2"