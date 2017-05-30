{isFunction, isString, isArray} = require("./_helpers")
module.exports =
  _name: "mount"
  _v: 1
  methods: 
    $mount: ({anchor, els, template}) ->
      if isFunction(els)
        template = els
      cerror !template, "$mount called without template"
      els = null
      append = (els) ->
        if isArray(els)
          parent = anchor.parentElement
          for el in els
            parent.insertBefore el, anchor
      if isString(template)
        @$computed.orWatch template, (fn) ->
          if isArray(els)
            for el in els
              el.remove()
          if fn and isFunction(fn)
            els = fn.call(@)
            append(els)
      else
        els = template.call(@)
        append(els)


test module.exports, (merge) ->
  describe "ceri", ->
    describe "mount", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <div #ref=anchor></div>
            """)
          data: ->
            template: -> [document.createElement "p"]
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
        el.$mount anchor: el.anchor, template: "template"
        el.should.contain "p+div"
        el.template = ->
        el.should.not.contain "p+div"
      it "should work directly", ->
        el.$mount anchor: el.anchor, template: ->     [document.createElement "p"]
        el.should.contain "p+div"