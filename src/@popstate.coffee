{noop} = require("./_helpers")
cbs = []
window.onpopstate = (e) ->
  for o in cbs
    for cb in o._cbs
      cb.call(o.this,e)

module.exports =
  _name: "@popstate"
  _v: 1
  _evLookup: 
    popstate: (o) ->
      o.this = @
      o.activate = ->
        cbs.push o
        return -> cbs.splice cbs.indexOf(o), 1
      return o