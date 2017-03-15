# http://andylangton.co.uk/blog/development/get-viewport-size-width-and-height-javascript

module.exports =
  methods:
    getViewportSize: ->
      if window.innerWidth?
        e = window
        a = 'inner'
      else
        a = 'client'
        e = document.documentElement || document.body
      return { width : e[ a+'Width' ] , height : e[ a+'Height' ] }
