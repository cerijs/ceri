
module.exports =
  _name: "#if"
  _v: 1
  mixins: [
    require("./structure")
  ]
  _attrLookup:
    if: 
      "#": (el, path, mods) ->
        @$structure.beforeInsert.push (structure) ->
          comment = document.createComment("#if")
          parent = el.parentNode || @
          if parent == @
            {value} = @$path.toValue path:path
            unless value
              index = structure.indexOf(el)
              structure[index] = comment
          @$watch.path path:path, cbs: (value, oldVal) ->
            if value and comment.parentNode == parent
              parent.replaceChild el, comment
            else if !value and el.parentNode == parent
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