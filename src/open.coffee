module.exports =
  _name: "open"
  _v: 1
  props:
    open:
      type: Boolean
  data: ->
    isOpen: null
    opening: false
    closing: false
    openingOrOpen: false
    toggleAnimate: true
  methods:
    show: (animate) ->
      return if @openingOrOpen
      if not @parentElement 
        if @onBody
          document.body.appendChild @
        else
          @__parentElement.replaceChild @, @__placeholder
      @toggleAnimate = animate != false
      @opening = true
      @openingOrOpen = true
      @closing = false
      @beforeShow?(animate)
      done = ->
        @opening = false
        @isOpen = true
        @open = true
        @$emit name:"toggle", detail:true
        @afterOpen?()
      if @$animate and @enter?
        @animation = @enter @$cancelAnimation @animation,
          animate: animate
          done: done
      else
        done.call(@)

    hide: (animate) ->
      return if @closing or not @isOpen
      @toggleAnimate = animate != false
      @closing = true
      @openingOrOpen = false
      @beforeHide?(animate)
      done = ->
        @isOpen = false
        @open = false
        if @parentElement
          if @onBody
            @remove()
          else if @parentElement == @__parentElement
            @__parentElement.replaceChild @__placeholder, @
        @closing = false
        @$emit name:"toggle", detail:false
        @afterClose?()
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
      spy = chai.spy()
      before (done) ->
        el = makeEl merge {}
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
