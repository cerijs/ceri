module.exports =
  _name: "open"
  _v: 1
  mixins: [
    require "./computed"
    require "./events"
    require "./@popstate"
  ]
  events:
    popstate:
      active: -> @onBody and @openingOrOpen
      cbs: -> @hide(false)
    click:
      el: document.documentElement
      outside: true
      cbs: "hide"
      active: -> @openingOrOpen and not @keepOpen
      delay: true
      destroy: true
    keyup:
      el:document.documentElement
      notPrevented: true
      destroy: true
      keyCode: [27]
      active: -> @openingOrOpen and not @keepOpen
      cbs: "hide"
  props:
    open:
      type: Boolean
    keepOpen:
      type: Boolean
  data: ->
    isOpen: null
    opening: false
    closing: false
    openingOrOpen: false
    toggleAnimate: true
  methods:
    _attach: ->
      if not @parentElement 
        if @onBody
          document.body.appendChild @ if @parentElement != document.body
        else if @parentElement != @__parentElement
          @__parentElement.replaceChild @, @__placeholder
    _detach: ->
      if @parentElement
        if @onBody
          @remove() if @parentElement == document.body
        else if @parentElement == @__parentElement
          @__parentElement.replaceChild @__placeholder, @
    _setOpen: ->
      @closing = false
      @opening = false
      @isOpen = true
      @open = true
      @openingOrOpen = true
      @$emit name:"toggle", detail:true
      @onOpen?()
    _setClose: ->
      @closing = false
      @opening = false
      @isOpen = false
      @open = false
      @openingOrOpen = false
      @$emit name:"toggle", detail:false
      @onClose?()
    show: (animate) ->
      return if @openingOrOpen
      @_attach()
      @toggleAnimate = animate = animate != false
      @opening = true
      @openingOrOpen = true
      @closing = false
      @onShow?(animate)
      if @$animate and @enter?
        @animation = @enter @$cancelAnimation @animation,
          animate: animate
          done: @_setOpen
      else
        @setOpen(@)
    hide: (animate) ->
      return if @closing or not @openingOrOpen
      @toggleAnimate = animate = animate != false
      @closing = true
      @openingOrOpen = false
      @onHide?(animate)
      done = ->
        @_setClose()
        @_detach()
      if @$animate and @leave?
        @animation = @leave @$cancelAnimation @animation,
          animate: animate
          done: done
      else
        done.call(@)
          
    toggle: (animate) ->
      return if @beforeToggle? and not @beforeToggle(animate)
      if @isOpen
        @hide(animate)
      else
        @show(animate)
  watch:
    open: (val) ->
      unless @isOpen?
        if val
          @toggle(false)
        else
          @isOpen = val
      else
        if val != @isOpen
          @toggle()
  connectedCallback: ->
    if @_isFirstConnect
      @__parentElement = @parentElement
      @__placeholder = document.createComment("#open")
      @__parentElement.replaceChild @__placeholder, @
  disconnectedCallback: ->
    if @isOpen
      @toggle(false)
test module.exports, (merge) ->
  describe "ceri", ->
    describe "open", ->
      el = null
      spy = sinon.spy()
      before (done) ->
        el = makeEl merge {}
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
