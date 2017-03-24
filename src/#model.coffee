
module.exports =
  _name: "#model"
  _v: 1
  mixins: [
    require("./directives")
  ]
  _attrLookup:
    model: 
      "#": (o) ->
        event = switch o.el.type
          when "checkbox","radio","select-one","select-multiple" then "change"
          else "input"
        o.path = o.value
        @$path.toNameAndParent(o)
        o.el.addEventListener event, (e) =>
          if o.parent[o.name] != e.target.value
            o.parent[o.name] = e.target.value
        @$watch.path path:o.value, cbs: (value) ->
          if o.el.value != value
            o.el.value = value


test module.exports, (merge) ->
  describe "ceri", ->
    describe "#model", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <input #model="value" #ref=input></input>
            <select #model="value" #ref=select></select>
            """)
          data: -> 
            value: "test"
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
        el.input.value.should.equal el.value