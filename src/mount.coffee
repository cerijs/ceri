{isFunction, isString, isArray} = require("./_helpers")
module.exports =
  _name: "mount"
  _v: 1
  mixins: [
    require "./parseFunction"
  ]
  methods: 
    $mount: ({anchor, els, template}) ->
      if isFunction(els)
        template = els
      cerror !template, "$mount called without template"
      els = null
      @$parseFunction template, (fn) ->
        if isArray(els)
          for el in els
            el.remove()
        if fn and isFunction(fn)
          els = fn.call(@)
          if isArray(els)
            parent = anchor.parentElement
            for el in els
              parent.insertBefore el, anchor


test module.exports, {
  mixins: [ require("./structure") ]
  structure: template(1,"""
    <div #ref=anchor></div>
    """)
  data: ->
    template: -> [document.createElement "p"]
}, (el) ->
  it "should work", ->
    el.$mount anchor: el.anchor, template: "template"
    el.should.contain "p+div"
    el.template = ->
    el.should.not.contain "p+div"
  it "should work directly", ->
    el.$mount anchor: el.anchor, template: ->     [document.createElement "p"]
    el.should.contain "p+div"