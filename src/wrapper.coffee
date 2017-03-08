ceri = require "./ceri"

module.exports = (parent, obj) ->
  unless obj?
    obj = parent
    parent = HTMLElement
  cls = obj.constructor = (self) ->
    self = parent.call(self or @)
    for fn in self._crCb
      fn.call(self)
    return self
  cls.prototype = Object.create parent.prototype
  for k,v of obj
    cls.prototype[k] = v
  return ceri(cls)