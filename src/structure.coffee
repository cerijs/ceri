{isElement,isString,arrayize,camelize} = require("./_helpers")
module.exports =
  _name: "structure"
  _v: 1
  _prio: 800
  _mergers: [
    require("./_merger").copy(source: "_elLookup")
    require("./_merger").copy(source: "_attrLookup")
    ]
  _rebind: "$structure"
  mixins: [
    require("./watch")
    require("./setAttribute")
    require "./events"
  ]
  _attrLookup:
    text: 
      ":": (el, val) -> @$watch.path path: val, cbs: (val) -> el.textContent = val
      "#": (el, val) -> el.textContent = val

    ref: 
      "#": (el, val) -> @[val] = el

  methods:
    "$structure":
      beforeInsert: []
      afterInsert: []
    el: (name, options, children) ->
      if @_elLookup?[name]?
        el = @_elLookup[name].call(@, name)
      else
        el = document.createElement(name)

      if options?
        for name, types of options
          lookupObj = @_attrLookup[name]
          for type, value of types
            if value.mods?
              mods = value.mods
              value = value.val
              if mods.camel
                name = camelize(name)
            else
              mods = {}
            if lookupObj?
              if lookupObj[type]?
                lookupObj[type].call @, el, value, mods
                continue
              cwarn(!lookupObj[type]?, type, name," found, but not expected")
            switch type 
              when "$"
                @$watch.path path: value, cbs: ((el,name,val) -> el[name] = val).bind(@,el,name)
              when ":"
                @$watch.path path: value, cbs: @$setAttribute.bind(@,el,name)
              when "@"
                if mods.toggle
                  mods.toggle = value
                else
                  mods.cbs = [value]
                mods.event ?= name
                mods.el ?= el
                @$on mods
              when "~"
                unless @[name]?
                  @[name] = =>
                    for cb in @[name]._cbs
                      cb.apply null, arguments
                if mods?.event
                  cb = ((el, value, e) -> el.dispatchEvent value, e).bind null, el, value
                else
                  cb = ((el, value, args...) -> el[value].apply null, args).bind null, el, value
                @[name]._cbs.push cb
              else
                el.setAttribute name, value
      if children?
        for child in children
          if isString(child)
            @_slots[child] = el
          else
            el.appendChild child
      return el
  created: ->
    @_slots = {}
  connectedCallback: ->
    if @_isFirstConnect and @structure?
      structure = arrayize(@structure())
      for fn in @$structure.beforeInsert
        fn.call(@, structure)
      for child in @children
        if child?
          slot = child.getAttribute "slot"
          if slot?
            @_slots[slot]?.appendChild(slot)
          else
            @_slots.default?.appendChild(child)
      for el in structure
        if isString(el)
          @_slots[el] = @
        else
          @appendChild(el)
      for fn in @$structure.afterInsert
        fn.call(@)

test module.exports, (merge) ->
  describe "ceri", ->
    describe "structure", ->
      el = null
      spy = chai.spy()
      before ->
        el = makeEl merge({
          structure: template(1,"""
            <div #ref="someDiv" @click="onClick" :text="someText" :bind="someBind" attr="someAttr">
              <slot>
              </slot>
            </div>
            """)
          methods:
            onClick: spy
          data: ->
            someText: "textContent"
            someBind: "bindContent"
        }),false
        el.appendChild(document.createElement "div")
      after -> el.remove()
      it "should not work until attached", ->
        should.not.exist el.someDiv
      it "should have the right structure once on dom", (done) ->
        document.body.appendChild el
        el.$nextTick ->
          el.should.have.html "<div bind=\"bindContent\" attr=\"someAttr\">textContent<div></div></div>"
          done()
        
