
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
        @$style.set o.el, visibility: "hidden"
        @$watch.path path:o.value, cbs: (value, oldVal) ->
          style = visibility: if value then null else "hidden"
          if value and o.delay
            @$nextTick -> @$style.set o.el, style
          else
            @$style.set o.el, style


test module.exports, (merge) ->
  describe "ceri", ->
    describe "#show", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <div #show="isVisible" #ref=d1 class=c1></div>
            <div #show="isVisible2" #ref=d2 class=c2></div>
            """)
          data: ->
            isVisible: true
            isVisible2: false
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
        el.d1.should.not.have.attr "style", "visibility: hidden;"
        el.d2.should.have.attr "style", "visibility: hidden;"
        el.isVisible = false
        el.isVisible2 = true
        el.d1.should.have.attr "style", "visibility: hidden;"
        el.d2.should.not.have.attr "style", "visibility: hidden;"