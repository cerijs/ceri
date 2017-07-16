cbs = []
window.onpopstate = (e) ->
  for o in cbs
    o.cb.call(o.this,window,e)

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