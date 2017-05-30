{isString,clone} = require("./_helpers")
module.exports =
  _name: "directives"
  _v: 1
  _prio: 800
  _mergers: [
    require("./_merger").concat source: "directives"
    require("./_merger").copy source: "_attrLookup"
    ]
  mixins: [
    require "./setAttribute"
    require "./parseElement"
    require "./events"
    require "./computed"
  ]
  _attrLookup:
    text: 
      ":": (o) ->  @$computed.orWatch o.value, (val) -> o.el.innerText = val
      "#": (o) -> o.el.textContent = o.value
    ref: 
      "#": (o) -> @[o.value] = o.el
  methods:
    $directive: (o) ->
      @$parseElement.byObj(o)
      cerror(!o.el, o.type, o.name," tried on not existing element")
      if (lookupObj = @_attrLookup[o.name])?
        if lookupObj[o.type]?
          return lookupObj[o.type].call @, o
        #cwarn(!lookupObj[o.type]?, o.type, o.name," found, but not expected")
      switch o.type 
        when "$"
          cb = ((el,name,val) -> el[name] = val).bind(@,o.el,o.name)
          @$computed.orWatch o.value, [cb]
        when ":"
          cb = @$setAttribute.bind(@,o.el,o.name)
          @$computed.orWatch o.value, [cb]
        when "@"
          o.cbs ?= [o.value]
          o.event ?= o.name
          if o.event and o.cbs.length > 0
            @$on o
        when "~"
          unless @[o.name]?
            @[o.name] = =>
              for cb in @[o.name]._cbs
                cb.apply null, arguments
          if o.event
            cb = ((el, value, e) -> el.dispatchEvent value, e).bind null, o.el, o.value
          else
            cb = ((el, value, args...) -> el[value].apply null, args).bind null, o.el, o.value
          @[o.name]._cbs.push cb
        else
          @$setAttribute o.el, o.name, o.value
  connectedCallback: ->
    if @_isFirstConnect
      for directives in @directives
        for k,v of directives
          o = clone(v)
          o.el ?= k
          if o.activate?
            o.activated = false
            @$computed.orWatch o.activate, (val) ->
              if val and not o.activated
                @$directive o
                o.activated = true
          else
            @$directive o
          
              
        
test module.exports, (merge) ->
  describe "ceri", ->
    describe "directives", ->
      el = null
      before (done) ->
        el = makeEl merge {}
        el.$nextTick done
      after -> el.remove()
