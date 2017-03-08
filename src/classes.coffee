module.exports =
  _name: "classes"
  _v: 1
  _prio: 700
  _mergers: require("./_merger").copy(source: "classes")
  mixins: [
    require("./class")
    require("./combined")
  ]
  created: ->
    @$combined
      path: "classes"
      value: @classes
      parseProp: @$class.strToObj
      cbFactory: (name) ->
        if name == "this"
          el = @
        else
          el = @[name]
        return [(val) ->
          @$class.set el, val]


test module.exports, (merge) ->
  describe "ceri", ->
    describe "classes", ->
      el = null
      before (done) ->
        el = makeEl merge 
          mixins: [
            require("./structure")
            require("./props")
          ]
          structure: template(1,"""
            <div #ref="someDiv"></div>
            """)
          data: -> someClass: true
          props:
            class2:
              type: String
          classes:
            this:
              computed: -> someClass: @someClass
              data: -> someDataClass: true
              prop: "class2"
            someDiv:
              data: -> someData2Class: true
        el.$nextTick done
      after -> el.remove()
          
      it "should work", ->
        el.class2 = "somePropClass"
        el.should.have.attr "class", "somePropClass someClass someDataClass"
        el.classes.this.someDataClass = false
        el.should.have.attr "class", "somePropClass someClass"
        el.someDiv.should.have.attr "class", "someData2Class"
      after ->
        el.remove()
