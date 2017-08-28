{isFunction} = require("./_helpers")
module.exports =
  _name: "if"
  _v: 1
  mixins: [
    "parseFunction"
  ]
  methods: 
    $if: (o) ->
      cerror(!o.value,"no value provided for $if") 
      template = if isFunction(o.els) then o.els  else o.template
      elseTemplate = o.elseTemplate
      els = if template then null else o.els
      append = (els) ->
        if els?
          parent = o.parent || o.anchor.parentElement
          for el in els
            if el.parentElement != parent
              parent.insertBefore el, o.anchor
      remove = (els) ->
        if els?
          for el in els
            el.remove()
      els2 = if elseTemplate then null else o.else
      @$computed.orWatch o.value, (value, oldVal) ->
        truthy = !value != !o.not
        if truthy
          if template?
            @$parseFunction template, (fn) ->
              oldEls = els
              if fn? and isFunction(fn)
                els = fn.call(@)
              else
                els = []
              if truthy == true
                append(els)
                remove(oldEls)
            template = null
          else
            append(els) if els
          remove(els2) if els2
        else
          if elseTemplate?
            @$parseFunction elseTemplate, (fn) ->
              oldEls = els2
              if fn? and isFunction(fn)
                els2 = fn.call(@)
              else
                els2 = []
              if truthy == false
                append(els2)
                remove(oldEls)
            elseTemplate = null
          else
            append(els2) if els2
          remove(els) if els


test module.exports, {
  mixins: [ require("./structure") ]
  structure: template(1,"""
    <div #ref=anchor></div>
    """)
  data: ->
    isVisible: false
}, (el) ->
  it "should work", ->
    el.$if anchor:el.anchor, els:[document.createElement("p")], value: "isVisible"
    el.$if anchor:el.anchor, template: (-> [document.createElement("p")]), value: "isVisible"
    el.should.not.contain "p"
    el.isVisible = true
    el.should.contain "p"
    el.should.contain "p+p"
    for ele in document.querySelectorAll("p")
      ele.textContent = "test"
    el.isVisible = false
    el.should.not.contain "p"
    el.isVisible = true
    el.should.have.text "testtest"