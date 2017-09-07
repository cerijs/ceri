{isElement,isString,isFunction,arrayize,camelize} = require("./_helpers")
extract = (options, extr) ->
  return [null, options] unless extr
  opts = {}
  for type, names of extr
    t = if type == "@" then "on-" else type
    for name in names
      if (val = options[name]?[type])?
        delete options[name][type]
        delete options[name] if Object.keys(options[name]).length == 0
        opts[camelize(t+name)] = val
  return [options, opts]
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
      if (o = @_elLookup?[camelize(name)])?
        o = cb: o unless o.cb?
        [options, opts] = extract(options, o.extract)
        el = o.cb.call(@, opts, children: children, name: name)
        if el.el?
          options ?= el.options
          children = el.children
          el = el.el
      else
        el = document.createElement(name)
      if options?
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
      if children? and not isFunction(children)
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
        
