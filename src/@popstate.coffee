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
      remover = noop
      o.this = @
      adder = ->
        cbs.push o
        remover = ->
          cbs.splice cbs.indexOf(o), 1
          remover = noop
      return adder: adder, remover: remover