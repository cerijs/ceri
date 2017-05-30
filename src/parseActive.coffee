{noop,isString} = require("./_helpers")
module.exports =
  _name: "parseActive"
  _prio: 10000
  _v: 1
  mixins: [
    require "./computed"
  ]
  methods:
    $parseActive: (o) ->
      shouldActivate = false
      deactivate = noop
      activate = =>
        return unless shouldActivate
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
      activateWrapper = =>
        shouldActivate = true
        if o.delay
          @$nextTick activate
        else
          activate()
      if o.active
        @$computed.orWatch o.active, (val, oldVal) ->
          if val != oldVal
            if val
              activateWrapper()
            else
              shouldActivate = false
              deactivate()
      else
        activateWrapper()
        

  connectedCallback: ->
    if @_isFirstConnect
      @__activeToDestroy = []

  destroy: ->
    for cb in @__activeToDestroy
      cb()