
module.exports =
  _name: "#show"
  _v: 1
  mixins: [
    require("./structure")
    require("./style")
  ]
  _attrLookup:
    show: 
      "#": (el, path, mods) ->
        @$style.set el, visibility: "hidden"
        @$watch.path path:path, cbs: (value, oldVal) ->
          if value != oldVal
            style = visibility: if value then null else "hidden"
            if value and mods?.delay
              @$nextTick -> @$style.set el, style
            else
              @$style.set el, style


test module.exports, (merge) ->
  describe "ceri", ->
    describe "#show", ->
      el = null
      before (done) -> 
        el = makeEl merge
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