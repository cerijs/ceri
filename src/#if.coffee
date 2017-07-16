
module.exports =
  _name: "#if"
  _v: 1
  mixins: [
    require "./directives"
    require "./if"
  ]
  _attrLookup:
    if: 
      "#": (o) ->
        comment = document.createComment("#if")
        parent = o.el.parentElement
        cb = => @$if value: o.value, anchor: comment, els: [o.el], not: o.not
        if parent
          parent.appendChild(comment)
          cb()
        else if @$structure
          @$structure.beforeInsert.push (structure) ->
            index = structure.indexOf(o.el)
            if index > -1
              value = @$path.getValue o.value
              unless value
                structure[index] = comment
              else
                structure.splice index, 0, comment
            else
              @$structure.afterInsert.push ->
                o.el.parentElement.insertBefore comment, o.el.nextSibling
            @$structure.afterInsert.push cb
        else 
          cwarn true, "#if: no parent found for element: " + o.el
          return null
            


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