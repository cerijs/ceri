body = document.body
docEl = document.documentElement
module.exports =
  methods:
    getScrollPos: ->
      top: window.pageYOffset || docEl.scrollTop || body.scrollTop
      left: window.pageXOffset || docEl.scrollLeft || body.scrollLeft