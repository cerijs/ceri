ceri = require "./ceri"

module.exports = (parent, obj) ->
  unless obj?
    obj = parent
    parent = HTMLElement
  try
    if window.customElements.define.name != "define"
      throw new Error "polyfill detected - fallback to ES5 class"
    cls = `class Ceri extends parent {
      constructor () {
        super()
        if (this._crCb) {
          this._crCb.forEach(cb => {
            cb.call(this)
          })
        }
        return this
      }
    }`
  catch e
    cls = obj.constructor = (self) ->
      self = parent.call(self or @)
      if self._crCb
        for fn in self._crCb
          fn.call(self)
      return self
  cls.prototype = Object.create parent.prototype
  for k,v of obj
    cls.prototype[k] = v
  return ceri(cls)