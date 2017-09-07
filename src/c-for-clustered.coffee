{isFunction} = require("./_helpers")
module.exports =
  _name: "c-for-clustered"
  _v: 1
  mixins:[
    require("./for-clustered")

  ]
  _elLookup:
    cForClustered:
      extract:
        "": ["tag","names","template","get-count","get-data","computed","id","tap"] 
      cb: (o, {children}) ->
        c = o.container = document.createElement(o.tag or "div")
        o.template = children if isFunction(children)
        o.names = o.names?.split(",")
        @$nextTick ->
          clusterContainer = @$clusteredFor o
          @$path.setValue(path:o.tap, value: clusterContainer) if o.tap?
        return c

test module.exports, {}, (merge) ->
  it "should work", ->