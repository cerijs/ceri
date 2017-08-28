{arrayize,hyphenate,camelize,clone} = require("./_helpers")
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
        unless ~arr.indexOf(hyphenated)
          arr.push hyphenated
      Object.defineProperty obj, "observedAttributes", value: arr
  mixins: [
    require("./watch")
    require("./setAttribute")
  ]     
  attributeChangedCallback: (name, oldVal, newVal) ->
    camelized = camelize(name)
    return unless (prop = @props[camelized])?
    if prop.type == Number and newVal?
      val = Number(newVal)
    else if prop.type == Boolean
      val = newVal?
    else
      val = newVal
    camelized = prop.name if prop.name?
    if @[camelized] != val
      @[camelized] = val
  created: ->
    @props ?= {}
    for k,v of @props
      unless v.type?
        v = type: v, name: k
        @props[k] = v
      else
        v.name ?= k
      if v.type == Boolean and not v.default?
        v.default = false
      o = clone(v)
      o.parent = @
      o.value = @[o.name]
      o.cbs = arrayize(o.cbs).concat([@$setAttribute.bind(@,@,hyphenate(o.name))])
      o.path ?= o.name
      o.initial ?= false
      @$watch.path o
  connectedCallback: ->
    if @_isFirstConnect
      @$nextTick ->
        for k,v of @props
          if v.default?
            if v.name
              name = v.name
            else
              name = k
            @[name] ?= v.default
        

test module.exports, {
  props: 
    someString: String
    someNumber: Number
    someBoolean: Boolean
    withDefault:
      type: String
      default: "defaultvalue"
}, (el) ->
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
    el.someBoolean.should.be.false
    el.should.not.have.attr "some-boolean"
    el.someBoolean = true
    el.should.have.attr "some-boolean"
    el.removeAttribute "some-boolean"
    el.$nextTick ->
      el.someBoolean.should.be.false
      done()
  it "should set defaults", ->
    el.withDefault.should.equal "defaultvalue"