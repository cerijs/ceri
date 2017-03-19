
module.exports =
  _name: "#model"
  _v: 1
  mixins: [
    require("./structure")
  ]
  _attrLookup:
    model: 
      "#": (el, path, mods) ->
        event = switch el.type
          when "checkbox","radio","select-one","select-multiple" then "change"
          else "input"
        o = @$path.toNameAndParent(path:path)
        el.addEventListener event, (e) =>
          if o.parent[o.name] != e.target.value
            o.parent[o.name] = e.target.value
        @$watch.path path:path, cbs: (value) ->
          if el.value != value
            el.value = value


test module.exports, (merge) ->
  describe "ceri", ->
    describe "#model", ->
      el = null
      before (done) -> 
        el = makeEl merge
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