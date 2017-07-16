{isElement,isString,isFunction,arrayize,camelize} = require("./_helpers")
module.exports =
  _name: "structure"
  _v: 1
  _prio: 800
  _mergers: [
    require("./_merger").copy(source: "_elLookup")
    ]
  _rebind: "$structure"
  mixins: [
    require "./directives"
  ]

  methods:
    "$structure":
      beforeInsert: []
      afterInsert: []
    el: (name, options, children) ->
      if (cb = @_elLookup?[camelize(name)])?
        el = cb.call(@, name, options, children)
      else
        el = document.createElement(name)
      if options? and (not cb? or cb.length < 2)
        for name, types of options
          for type, value of types
            if value.mods?
              o = value.mods
              o.value = value.val
            else
              o = value: value
            o.el = el
            o.type = type
            o.name = if o.camel then camelize(name) else name
            @$directive o
      if children? and not isFunction(children) and (not cb? or cb.length < 3)
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
      @$structure = null

test module.exports, (merge) ->
  describe "ceri", ->
    describe "structure", ->
      el = null
      spy = sinon.spy()
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
        
