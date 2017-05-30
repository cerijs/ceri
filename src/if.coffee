{isFunction} = require("./_helpers")
module.exports =
  _name: "if"
  _v: 1
  methods: 
    $if: ({anchor, els, template, value, elseTemplate}) ->
      cerror(!value,"no value provided for $if") 
      if isFunction(els)
        template = els
      if template
        els = null
      append = (els) ->
        parent = anchor.parentElement
        for el in els
          if el.parentElement != parent
            parent.insertBefore el, anchor
      remove = (els) ->
        for el in els
          el.remove()
      els2 = null
      @$computed.orWatch value, (value, oldVal) ->
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