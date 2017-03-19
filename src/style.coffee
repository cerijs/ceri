prefixes = ["Webkit", "Moz", "ms"]
{camelize, capitalize, isArray} = require "./_helpers"

module.exports =
  _name: "style"
  _v: 1
  _rebind: "$style"
  _prio: 700
  _mergers: require("./_merger").copy(source: "initStyle")
  methods:
    $style:
      normalize: (prop) ->
        prop = camelize(prop)
        return prop if @style[prop]?
        prop = capitalize(prop)
        for prefix in prefixes
          prefixed = prefix+prop
          return prefixed if @style[prefixed]?
        return null
      normalizeObj: (obj) ->
        tmp = {}
        normalize = @$style.normalize
        for k,v of obj
          tmp[normalize(k)] = v
        return tmp
      setNormalized: (el, obj) ->
        for k,v of obj
          if isArray(v) and v[0]?
            el.style[k] = v.join("")
          else
            el.style[k] = v
      set: (el, obj) ->
        unless obj?
          obj = el
          el = @
        @$style.setNormalized(el,@$style.normalizeObj(obj))
  connectedCallback: ->
    if @_isFirstConnect and @initStyle?
      @$style.set @, @initStyle


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
