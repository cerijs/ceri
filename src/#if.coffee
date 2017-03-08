
module.exports =
  _name: "#if"
  _v: 1
  mixins: [
    require("./structure")
  ]
  _attrLookup:
    if: 
      "#": (el, path) ->
        comment = document.createComment("#if")
        parent = null
        @__deferredStructure.push ->
          parent = el.parentNode
          {value} = @$path.toValue path: path
          unless value
            parent.replaceChild comment, el
        @$watch.path path:path, initial: false, cbs: (value) ->
          if value
            parent.replaceChild el, comment
          else
            parent.replaceChild comment, el



test module.exports, (merge) ->
  describe "ceri", ->
    describe "#if", ->
      el = null
      before (done) -> 
        el = makeEl merge
          structure: template(1,"""
            <div #if="isVisible" class=c1></div>
            <div #if="isVisible2" class=c2></div>
            """)
          data: ->
            isVisible: true
            isVisible2: false
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
        el.should.contain "div.c1"
        el.should.not.contain "div.c2"
        el.isVisible = false
        el.should.not.contain "div.c1"
        el.isVisible2 = true
        el.should.contain "div.c2"