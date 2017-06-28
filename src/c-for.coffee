{isFunction} = require("./_helpers")
module.exports =
  _name: "c-for"
  _v: 1
  mixins: [
    require "./structure"
    require "./for"
  ]
  _elLookup:
    cFor: (name, o, children) ->
      comment = document.createComment("c-for")
      if isFunction(children)
        template = children
      else
        template = o.template?[""]
      @$nextTick ->
        objs = @$for
          anchor: comment
          template: template
          value: o.iterate?[""]
          names: o.names?[""]?.split(",")
          computed: o.computed?[""]
        if (tap = o.tap?[""])?
          @$path.setValue(path:tap, value: objs)
      return comment

test module.exports, (merge) ->
  describe "ceri", ->
    describe "cfor", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <c-for names="item,i1,i2" iterate=arr>
              <template>
              <span :text.expr="this.i1+' '+this.item+this.i2"></span>
              </template>
            </c-for>
            """)
          data: ->
            arr: [3,2,1]
              
        setTimeout done, 50
      after -> el.remove()
      it "should work with arrays", ->
        el.should.have.text "0 31 22 1"
        el.arr = [1,1,1]
        el.should.have.text "0 11 12 1"
        el.arr = [2,2]
        el.should.have.text "0 21 2"
        el.arr = [3,3,3]
        el.should.have.text "0 31 32 3"
      it "should work with objects", ->
        el.arr =
          1: 3
          2: 2
          3: 1
        el.should.have.text "1 302 213 12"