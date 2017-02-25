{isElement,isString,arrayize} = require("./_helpers")
getByAlias = (obj, alias) ->
  for a in alias
    if obj[a]
      return obj[a]
  return null
module.exports =
  _name: "structure"
  _v: 1
  _prio: 800
  _mergers: [
    require("./_merger").copy(source: "_elLookup")
    require("./_merger").copy(source: "_attrLookup")
    ]
  mixins: [
    require "./path"
    require("./watch")
  ]
  _attrLookup:
    text: 
      ":": (el, val) -> @$watch.path path: val, cbs: (val) -> el.textContent = val
      "#": (el, val) -> el.textContent = val
    ref: 
      "#": (el, val) -> @[val] = el

  methods:
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
            if lookupObj?
              if lookupObj[type]?
                lookupObj[type].call @, el, value, mods
                continue
              else
                cwarn("true", type, name," found, but not expected")
            switch type 
              when "$"
                @$watch.path path: value, cbs: ((el,name,val) -> el[name] = val).bind(@,el,name)
              when ":"
                @$watch.path path: value, cbs: ((el,name,val) -> el.setAttribute name, val).bind(@,el,name)
              when "@"
                @_deferredStructure.push ((el, name, value, mods) ->
                  {value} = @$path.toValue(path: value) if isString(value)
                  if mods?
                    capture = mods.capture
                    fn = (e) ->
                      return if mods.self and e.target != el
                      return if mods.notPrevented and e.defaultPrevented
                      value.apply @, arguments
                      e.preventDefault() if mods.prevent
                      e.stopPropagation() if mods.stop
                      el.removeEventListener name,fn if mods.once
                  else
                    fn = value
                  fn = fn.bind(@)
                  el.addEventListener name, fn, capture
                  ).bind(@, el, name, value, mods)
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
      @_deferredStructure = []
      structure = arrayize(@structure())
      for child in @children
        slot = child.getAttribute "slot"
        if slot?
          @_slots[slot]?.appendChild(slot)
        else
          @_slots.default?.appendChild(child)
      for el in structure
        @appendChild(el)
      for fn in @_deferredStructure
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
        
