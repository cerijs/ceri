
if window.MutationObserver?
  allResizeCbs = []
  activate = (el, cb) ->
    elheight = el.offsetHeight
    elwidth = el.offsetWidth
    cbwrapper = ->
      if elheight != el.offsetHeight or elwidth != el.offsetWidth
        elheight = el.offsetHeight
        elwidth = el.offsetWidth
        cb.apply(null,arguments)
    allResizeCbs.push cbwrapper
    return ->
      if ~(i = allResizeCbs.indexOf(cbwrapper))
        allResizeCbs.splice i,1
  callAllResizeCbs = ->
    for cb in allResizeCbs
      cb.apply(null,arguments)
  observer = new MutationObserver callAllResizeCbs
  observer.observe document.body,
    attributes: true
    childList: true
    characterData: true
    subtree: true
  window.addEventListener "resize", callAllResizeCbs
else
  require "javascript-detect-element-resize"
  activate = (el, cb) ->
    window.addResizeListener(el, cb)
    return window.removeResizeListener.bind(null, el, cb)

module.exports =
  _name: "@resize"
  _v: 1
  mixins: [
    require "./events"
  ]
  _evLookup: 
    resize: (o) ->
      o.throttled ?= true
      o.activate = =>
        el = @$parseElement.byString(o.el)
        cb = o.cb.bind(@,el)
        return activate(el, cb)
      return o