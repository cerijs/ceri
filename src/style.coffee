prefixes = ["Webkit", "Moz", "ms"]
{camelize, capitalize, isArray, isFunction,clone, isObject} = require "./_helpers"

module.exports =
  _name: "style"
  _v: 1
  _rebind: "$style"
  _prio: 700
  _mergers: [
    require("./_merger").copy(source: "initStyle")
    require("./_merger").copy(source: "computedStyle")
  ]
  _attrLookup:
    style:
      "#": (o) ->  @$computed.orWatch o.value, (val) -> @$style.set o.el, val
  mixins: [
    require "./parseElement"
  ]
  methods:
    $style:
      normalize: (prop, el = @) ->
        prop = camelize(prop)
        el = @$parseElement.byString(el)
        return prop if el.style[prop]?
        prop = capitalize(prop)
        for prefix in prefixes
          prefixed = prefix+prop
          return prefixed if el.style[prefixed]?
        return null
      normalizeObj: (obj,el) ->
        tmp = {}
        normalize = @$style.normalize
        for k,v of obj
          key = normalize(k,el)
          tmp[key] = v if key
        return tmp
      setNormalized: (el, obj) ->
        el = @$parseElement.byString(el)
        for k,v of obj
          if isArray(v) and v[0]?
            el.style[k] = v.join("")
          else
            el.style[k] = v
      set: (el, obj) ->
        unless obj?
          obj = el
          el = @
        @$style.setNormalized(el,@$style.normalizeObj(obj,el))
  connectedCallback: ->
    if @_isFirstConnect
      if (ins = @initStyle)?
        unless isObject(ins[Object.keys(ins)[0]])
          ins = this: ins
        for el, s of ins
          @$style.set el, s
      if (cs = @computedStyle)?
        for el, c of cs
          @$computed.parseAndInit c, cbs: ((el, val) -> @$style.set(el, val)).bind(@,el)

test module.exports, (merge) ->
  describe "ceri", ->
    describe "style", ->
      el = null
      before ->
        el = makeEl merge {}
      after -> el.remove()
      it "should normalize style prop", ->
        el.$style.normalize("background-color").should.equal "backgroundColor"
      it "should normalize style obj", ->
        obj = el.$style.normalizeObj({"background-color":true,position:true})
        obj.backgroundColor.should.be.true
        obj.position.should.be.true
      it "should set style obj on element", ->
        el.$style.set({"background-color":"blue",position:"absolute"})
        el.should.have.attr "style", "background-color: blue; position: absolute;"
