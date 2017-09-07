module.exports =
  _name: "c-draghandle"
  _v: 1
  mixins:[
    require("./draghandle")

  ]
  _elLookup:
    cDraghandle:
      extract:
        "": ["tag","active"]
        "@":["start","first-move","move","click","end"] 
      cb: (o) ->
        h = o.handle = document.createElement(o.tag or "div")
        @$draghandle(o)
        return h

test module.exports, {}, (merge) ->
  it "should work", ->