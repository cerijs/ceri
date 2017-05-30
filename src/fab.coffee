module.exports =

  mixins:[
    require("./animate")
    require("./getViewportSize")
    require("./for")
    require("./parseActive")
    require("./style")
    require("./structure")
  ]

  methods:

    $fab: (o) ->
      o.activate = ->
        fab = document.createElement("div")
        comment = document.createComment("fab")
        fab.appendChild(comment)
        @$style.set fab, o.style if o.style
        @el
        o.close = =>
        return o.close
      return @$parseActive(o)


  connectedCallback: ->
    if @_isFirstConnect and @fab
      {clone} = require("./_helpers")
      @$fab(clone(@fab))
    