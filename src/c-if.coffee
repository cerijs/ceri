{isFunction} = require("./_helpers")
module.exports =
  _name: "c-if"
  _v: 1
  mixins: [
    require "./structure"
    require "./if"
  ]
  _elLookup:
    cIf: (name, o, children) ->
      comment = document.createComment("c-if")
      if o?
        @$nextTick ->
          @$if 
            value: o.true?[""] or o.false?[""]
            anchor: comment
            els: children
            template: o.template?[""]
            elseTemplate: o.else?[""]
            not: o.not?[""] or o.false?[""]?
      return comment


test module.exports, {
  mixins: [ require("./structure") ]
  structure: template(1,"""
    <c-if true=isVisible>
      <p>test</p>
    </c-if>
    <c-if true=isVisible template=template else=elseTemplate>
    </c-if>
    <c-if true=isVisible>
      <template><p>test3</p></template>
    </c-if>
    """)
  data: ->
    isVisible: false
    template: template(1,"<p>test2</p>")
    elseTemplate: template(1,"<p>else</p>")
}, (el) ->
  it "should work", ->
    el.should.have.text "else"
    el.isVisible = true
    el.should.have.text "testtest2test3"