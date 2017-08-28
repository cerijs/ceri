require("document-register-element/pony")(global,'force')

_mixins = []
ceri = null
window.test = (mixin, obj, cb) ->
  unless (name = mixin._name)? and ~_mixins.indexOf(name)
    _mixins.push name
    unless cb?
      cb = obj
      describe "ceri", ->
        describe name, ->
          cb (obj) ->
            obj.mixins ?= []
            obj.mixins.push mixin
            ceri ?= require("../src/wrapper.coffee")
            return ceri(obj)
    else
      obj.mixins ?= []
      obj.mixins.push mixin
      ceri ?= require("../src/wrapper.coffee")
      el = makeEl ceri(obj), false
      describe "ceri", ->
        describe name, ->
          before (done) ->
            document.body.appendChild el
            window.requestAnimationFrame -> done()
          after ->
            el.remove()
          cb.call(el, el)
            
      


i = 0
window.makeEl = (obj,append = true) ->
  name = "view-nr#{i++}"
  window.customElements.define name, obj
  el = document.createElement(name)
  if append
    document.body.appendChild el
  return el
