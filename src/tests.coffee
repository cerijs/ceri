module.exports =
  _name: "tests"
  _prio: 0
  _v: 1
  _mergers: [
    source: "tests"
    setup: -> iterate: ->
    finisher: (obj) ->
      if process.env.NODE_ENV == "test"
        window.ceri ?= {}
        window.ceri.tests ?= []
        window.ceri.tests.push obj
  ]
  created: ->
    if process.env.NODE_ENV == "test"
      @tests?(@)

test module.exports, (merge) ->
  describe "ceri", ->
    describe "tests", ->
      el = null
      obj = null
      spy = chai.spy()
      before -> obj = merge {tests: spy}
      after -> el?.remove()
      it "should put the object to test1", ->
        window.ceri.tests[0].should.equal obj
      it "should call tests once on dom", (done) ->
        spy.should.not.have.been.called()
        el = makeEl(obj)
        el.$nextTick ->
          spy.should.have.been.called.with el
          done()
