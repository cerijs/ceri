{isFunction} = require("./_helpers")
module.exports =
  _name: "if"
  _v: 1
  methods: 
    $if: (o) ->
      cerror(!o.value,"no value provided for $if") 
      template = if isFunction(o.els) then o.els  else o.template
      elseTemplate = o.elseTemplate
      els = if template then null else o.els
      append = (els) ->
        parent = o.anchor.parentElement
        for el in els
          if el.parentElement != parent
            parent.insertBefore el, o.anchor
      remove = (els) ->
        for el in els
          el.remove()
      els2 = null
      @$computed.orWatch o.value, (value, oldVal) ->
        value = !value != !o.not
        if value
          if template?
            els = @$path.resolveValue(template).call(@)
            template = null
          append(els) if els
          remove(els2) if els2
        else
          if elseTemplate?
            els2 = @$path.resolveValue(elseTemplate).call(@)
            elseTemplate = null
          append(els2) if els2
          remove(els) if els


test module.exports, (merge) ->
  describe "ceri", ->
    describe "if", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <div #ref=anchor></div>
            """)
          data: ->
            isVisible: false
        el.$nextTick done
      after -> el.remove()
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