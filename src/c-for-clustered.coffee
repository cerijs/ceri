
module.exports =
  _name: "c-for-clustered"
  _v: 1
  mixins:[
    require("./for-clustered")

  ]
  _elLookup:
    cClustered: (name, o, children) ->
      container = document.createElement "div"
      if isFunction(children)
        template = children
      else
        template = o.template?[""]
      @$nextTick ->
        clusterContainer = @$clusteredFor
          container: container
          template: template
          getCount: o.getCount?[""]
          getData: o.getData?[""]
          names: o.names?[""]?.split(",")
          computed: o.computed?[""]
          id: o.id?[""]
        if (tap = o.tap?[""])?
          @$path.setValue(path:tap, value: clusterContainer)
      return container

test module.exports, {}, (merge) ->
  it "should work", ->