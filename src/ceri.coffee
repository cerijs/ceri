# out ../../lib/ceri.js
{isObject, isFunction, isArray} = require("./_helpers")
module.exports = (ce) ->
  ceProto = ce.prototype
  ceProto.$nextTick = (cb) -> setTimeout cb.bind(@), 0
  if ceProto.mixins?
    ## flatten dependencies of mixins
    flattenMixins = (mixins) ->
      addMixins = []
      for mixin in mixins
        if mixin.mixins?
          addMixins = flattenMixins(mixin.mixins).concat addMixins
      for mixin in addMixins
        if mixins.indexOf(mixin) == -1
          mixins.push mixin
      return mixins
    flattenMixins(ceProto.mixins)

    ## merging mergers
    _merger = require("./_merger")
    _merger.apply(ce,ceProto.mixins,_merger.concat(source: "_mergers", target: "mergers"))
    mergers = ceProto.mergers

    delete ceProto.mergers
    ## prepare merging methods
    mergers.push _merger.copy source:"methods", target: false
    mergers.push _merger.concat source:"_rebind"
    ## prepare merging reactions
    addReactionMerger = (name,short) ->
      merger = _merger.concat(source:name, target:short, last: true)
      merger.finisher = (obj) ->
        obj.prototype[name] = ->
          for fn in @[short]
            fn.apply(@,arguments)
      mergers.push merger
    addReactionMerger "disconnectedCallback","_dCb"
    addReactionMerger "attributeChangedCallback","_acCb"
    addReactionMerger "adoptedCallback","_aCb"
    mergers.push _merger.concat
      source: "connectedCallback"
      target: "_cCb"
      last: true
      finisher: (obj)->
        obj.prototype.connectedCallback = ->
          for fn in @_cCb
            fn.apply(@,arguments)
          @_isFirstConnect = false
          
    addReactionMerger "destroy","_deCb"
    mergers.push source:"created", setup: (obj) ->
      obj._crCb = [->
        @_isCeri = true
        @_isFirstConnect = true
        proto = Object.getPrototypeOf(@)
        for key in @_rebind
          o1 = proto[key]
          cerror(!isObject(o1),"_rebind must target object: ", key)
          o2 = {}
          Object.defineProperty @, key, __proto__:null, value: o2 
          for k,v of o1
            if isFunction(v)
              o2[k] = v.bind(@)
            else if isArray(v)
              o2[k] = v.slice()
            else if isObject(v) and v?
              o2[k] = {}
              for k2,v2 of v
                o2[k2] = v2
            else
              o2[k] = v

      ]
      iterate: (entry) -> obj._crCb.push entry
      end: ->
        obj._crCb.push obj.created if obj.created?

    ## apply merging
    _merger.apply(ce,ceProto.mixins,mergers)
  return ce

test {_name:"ceri"}, (merge) ->
  describe "ceri", ->
    it "should have working $nextTick", (done) ->
      cls = merge {}
      val = false
      cls.prototype.$nextTick ->
        val.should.be.true
        done()
      val = true
    it "should merge methods", ->
      cls = merge
        mixins: [
          {mixins: [{methods: nestedMethod: true}]}
          {methods: mixinMethod: true}
        ]
        methods: baseMethod: true
      cls.prototype.nestedMethod.should.be.true
      cls.prototype.mixinMethod.should.be.true
      cls.prototype.baseMethod.should.be.true
    it "should merge callbacks", ->
      cls = merge
        mixins: [{
          created: "createdMixin"
          connectedCallback: "connectedMixin"
          disconnectedCallback: "disconnectedMixin"
          destroy: "destroyMixin"
          attributeChangedCallback: "attributeChangedMixin"
          adoptedCallback: "adoptedMixin"
        }]
        created: "createdBase"
        connectedCallback: "connectedBase"
        disconnectedCallback: "disconnectedBase"
        destroy: "destroyBase"
        attributeChangedCallback: "attributeChangedBase"
        adoptedCallback: "adoptedBase"
      cls.prototype._crCb[1].should.equal "createdMixin"
      cls.prototype._crCb[2].should.equal "createdBase"
      for [name,cbname] in [
            ["connected","_cCb"]
            ["disconnected","_dCb"]
            ["attributeChanged","_acCb"]
            ["adopted","_aCb"]
            ["destroy","_deCb"]
          ]
        cls.prototype[cbname][0].should.equal name+"Mixin"
        cls.prototype[cbname][1].should.equal name+"Base"
    it "should _rebind", (done)->
      makeEl merge
        mixins: [{
          _rebind: "$mixin"
          methods:
            $mixin:
              array: []
              obj: {}
              null: null
              fn: (el) ->
                @should.equal el
        }]
        created: ->
          should.exist @$mixin.array
          @$mixin.array.push true
          @$mixin.array.should.not.equal @__proto__.$mixin.array
          should.exist @$mixin.obj
          @$mixin.obj.should.not.equal @__proto__.$mixin.obj
          should.not.exist @$mixin.null
          should.exist @$mixin.fn
          @$mixin.fn(@)
          setTimeout (=> @remove()),0
          done()
      