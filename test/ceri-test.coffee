require("document-register-element/pony")(global,'force')

_mixins = []
window.test = (mixin, cb) ->
  unless mixin._name? and _mixins.indexOf(mixin._name) > -1
    _mixins.push mixin._name
    cb (obj) ->
      obj.mixins ?= []
      obj.mixins.push mixin
      return require("../src/wrapper.coffee")(obj)
i = 0
window.makeEl = (obj,append = true) ->
  name = "view-nr#{i++}"
  window.customElements.define name, obj
  el = document.createElement(name)
  if append
    document.body.appendChild el
  return el
