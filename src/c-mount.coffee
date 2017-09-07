module.exports =
  _name: "c-mount"
  _v: 1
  mixins: [
    require("./structure")
    require("./mount")
  ]
  _elLookup:
    "cMount":
      extract: 
        "": ["template"]
      cb: (options, {children}) ->
        comment = document.createComment("c-mount")
        @$nextTick ->
          @$mount
            anchor: comment
            els: children
            template: options.template
        return el: comment, options: null



test module.exports, {
  mixins: [ require("./structure") ]
  structure: template(1,"""
    <c-mount template=template></c-mount>
    <c-mount><template><p></p></template></c-mount>
    """)
  data: ->
    template: template 1, """<p></p>"""
}, (el) ->
  it "should work", ->
    el.should.contain "p"
    el.should.contain "p+p"