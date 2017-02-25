{arrayize,hyphenate,camelize} = require("./_helpers")
module.exports =
  _name: "props"
  _v: 1
  _prio: 900
  _mergers: require("./_merger").copy
    source: "props"
    finisher: (obj) ->
      arr = arrayize(obj.prototype.observedAttributes)
      for k,v of obj.prototype.props
        hyphenated = hyphenate(k)
        unless arr.indexOf(hyphenated) > -1
          arr.push hyphenated
      Object.defineProperty obj, "observedAttributes", value: arr
  _rebind: "$props"
  mixins: [
    require("./watch")
  ]
  methods:
    $props:
      parse: (name, val) ->
        return unless (prop = @props?[name])?
        if prop.type == Number and val?
          return Number(val)
        else if prop.type == Boolean
          return val?
        return val
      setAttribute: (name, val) ->
        hyphenated = hyphenate(name)
        switch @props[name].type
          when String,Number then @setAttribute(hyphenated,val)
          when Boolean
            if val
              @setAttribute(hyphenated,"")
            else
              @removeAttribute(hyphenated)
  attributeChangedCallback: (name, oldVal, newVal) ->
    camelized = camelize(name)
    if (val = @$props.parse(camelized,newVal))?
      camelized = @props[camelized].name if @props[camelized].name?
      if @[camelized] != val
        @[camelized] = val
  created: ->
    for k,v of @props
      unless v.type?
        @props[k] = type: v
        v = @props[k]
  connectedCallback: ->
    if @_isFirstConnect
      for k,v of @props
        if v.name
          name = v.name
        else
          name = k
        @[name] ?= v.default
        @$watch.init parent: @, name: name, path: name, value: @[name], initial: false, cbs: [@$props.setAttribute.bind(@,k)]

test module.exports, (merge) ->
  describe "ceri", ->
    describe "props", ->
      el = null
      before ->
        el = makeEl merge 
          props: 
            someString: String
            someNumber: Number
            someBoolean: Boolean
            withDefault:
              type: String
              default: "defaultvalue"
      after -> el.remove()
      it "should set observedAttributes", ->
        oa = el.__proto__.constructor.observedAttributes
        oa.length.should.equal 4
        for name in oa
          should.exist el.props[camelize(name)]
      it "should work with strings", (done) ->
        el.someString = "test"
        el.should.have.attr "some-string", "test"
        el.setAttribute "some-string", "test2"
        el.$nextTick ->
          el.someString.should.equal "test2"
          done()
      it "should work with numbers", (done) ->
        el.someNumber = 1
        el.should.have.attr "some-number","1"
        el.setAttribute "some-number", 2
        el.$nextTick ->
          el.someNumber.should.equal 2
          done()
      it "should work with boolean", (done) ->
        el.someBoolean = true
        el.should.have.attr "some-boolean"
        el.removeAttribute "some-boolean"
        el.$nextTick ->
          el.someBoolean.should.be.false
          done()
      it "should set defaults", ->
        el.withDefault.should.equal "defaultvalue"