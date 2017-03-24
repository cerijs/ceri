{noop} = require("./_helpers")
module.exports =
  _name: "parseActive"
  _v: 1
  mixins: [
    require "./computed"
  ]
  methods:
    $parseActive: (o) ->
      deactivate = noop
      activate = =>
        deactivate()
        _deactivate = o.activate.call(@)
        o.wasActivated = true
        deactivate = =>
          _deactivate.call(@)
          if o.destroy
            i = @__activeToDestroy.indexOf(_deactivate)
            @__activeToDestroy.splice i, 1 if i > -1
          _deactivate = noop
        @__activeToDestroy.push deactivate if o.destroy
        return deactivate
      if o.active
        @$computed.orWatch o.active, (val, oldVal) ->

          if val != oldVal
            if o._timeout?
              clearTimeout(o._timeout)
              o._timeout = null
            if val
              if o.delay
                o._timeout = @$nextTick activate
              else
                activate()
            else
              deactivate()
      else
        if o.delay
          @$nextTick activate
        else
          return activate()
        

  connectedCallback: ->
    if @_isFirstConnect
      @__activeToDestroy = []

  destroy: ->
    for cb in @__activeToDestroy
      cb()