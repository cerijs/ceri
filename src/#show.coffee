
module.exports =
  _name: "#show"
  _v: 1
  mixins: [
    require("./directives")
    require("./style")
  ]
  _attrLookup:
    show: 
      "#": (o) ->
        @$style.set o.el, display: "none"
        @$computed.orWatch o.value, (value, oldVal) ->
          value = !value != !o.not
          style = display: if value then null else "none"
          if value and o.delay
            @$nextTick -> @$style.set o.el, style
          else
            @$style.set o.el, style


test module.exports, {
  mixins: [ require("./structure") ]
  structure: template(1,"""
    <div #show="isVisible" #ref=d1 class=c1></div>
    <div #show="isVisible2" #ref=d2 class=c2></div>
    """)
  data: ->
    isVisible: true
    isVisible2: false
}, (el) ->
  it "should work", ->
    el.d1.should.not.have.attr "style", "display: none;"
    el.d2.should.have.attr "style", "display: none;"
    el.isVisible = false
    el.isVisible2 = true
    el.d1.should.have.attr "style", "display: none;"
    el.d2.should.not.have.attr "style", "display: none;"