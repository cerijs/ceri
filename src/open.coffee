module.exports =
  _name: "open"
  _v: 1
  props:
    open:
      type: Boolean
  data: ->
    isOpen: null
  methods:
    setOpen: ->
      unless @parentElement
        @__parentElement.replaceChild @, @__placeholder
      @isOpen = true
      @open = true
      @$emit name:"toggle", detail:true
    setClose: ->
      if @parentElement == @__parentElement
        @__parentElement.replaceChild @__placeholder, @
      @isOpen = false
      @open = false
      @$emit name:"toggle", detail:false
  watch:
    open: (val) ->
      unless @isOpen?
        if val
          @__noAnimation = true
          @toggle()
          @__noAnimation = false
      else
        if val != @isOpen
          @toggle()
  connectedCallback: ->
    if @_isFirstConnect
      @__parentElement = @parentElement
      @__placeholder = document.createComment("#open")
      @__parentElement.replaceChild @__placeholder, @

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
