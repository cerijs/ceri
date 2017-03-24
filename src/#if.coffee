
module.exports =
  _name: "#if"
  _v: 1
  mixins: [
    require "./directives"
  ]
  _attrLookup:
    if: 
      "#": (o) ->
        comment = document.createComment("#if")
        parent = o.el.parentElement
        cb = => @$computed.orWatch o.value, (value, oldVal) ->
          if value and comment.parentElement == parent
            parent.replaceChild o.el, comment
          else if !value and o.el.parentElement == parent
            parent.replaceChild comment, o.el
        if parent
          cb()
        else if @$structure
          @$structure.beforeInsert.push (structure) ->
            parent = @
            value = @$path.getValue o.value
            unless value
              index = structure.indexOf(o.el)
              structure[index] = comment
          @$structure.afterInsert.push cb
        else
          cwarn true, "#if: no parent found for element: " + o.el
            


test module.exports, (merge) ->
  describe "ceri", ->
    describe "#if", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
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