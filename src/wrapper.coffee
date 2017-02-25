ceri = require "./ceri"
module.exports = (obj) ->
  cls = class Ceri extends HTMLElement
    constructor: (self) ->
      super(self)
      for fn in self._crCb
        fn.call(self)
      return self
    test: ->
  for k,v of obj
    cls.prototype[k] = v
  return ceri(cls)