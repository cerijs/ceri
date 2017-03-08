# out: ../_throttledListener.js
called = []
fn = () -> called.push arguments
if document? and window?
  document.addEventListener "DOMContentLoaded", ->
    rAF = null
    cAF = null
    for pre in ["","moz","webkit","ms"]
      rAF ?= window[pre+"requestAnimationFrame"]
      cAF ?= window[pre+"cancelAnimationFrame"]
    if rAF
      fn = (el, event, cb) ->
        unless cb?
          cb = event
          event = el
          el = window
        lastRequest = null
        el.addEventListener event, ->
          args = arguments
          cAF(lastRequest)
          lastRequest = rAF -> cb.apply(null, args)
    else
      throttle = require("lodash/throttle")
      fn = (el, event, cb) ->
        unless cb?
          cb = event
          event = el
          el = window
        el.addEventListener event, throttle(cb, 66)
    for args in called
      fn.apply(null, args)
module.exports = fn
