{isString} = require("./_helpers")
module.exports =
  _name: "$setAttribute"
  _v: 1
  methods:
    $setAttribute: (el, name, val) ->
      if isString(el)
        val = name
        name = el
        el = @
      if val? and val != false and (isString(val) or !isNaN(val))
        if val == true
          el.setAttribute name, ""
        else
          el.setAttribute name, val
      else
        el.removeAttribute name
      return then: @$nextTick

test module.exports, (merge) ->
  describe "ceri", ->
    describe "$setAttribute", ->
      el = null
      before (done) ->
        el = makeEl merge {}
        el.$nextTick done
      after -> el.remove()
      it "should set boolean", (done) ->
        el.$setAttribute "test", true
        .then ->
          el.should.have.attr "test", ""
          el.$setAttribute "test", false
          .then ->
            el.should.not.have.attr "test"
            done()
      it "should set strings", (done) ->
        el.$setAttribute "test", "test"
        .then ->
          el.should.have.attr "test","test"
          el.$setAttribute "test", ""
          .then ->
            el.should.have.attr "test", ""
            el.$setAttribute "test", null
            .then ->
              el.should.not.have.attr "test"
              done()