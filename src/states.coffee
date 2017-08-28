{capitalize, isArray} = require("./_helpers")
getCan = (name) -> "can"+capitalize(name)
module.exports =
  _name: "states"
  _prio: 850
  _v: 1
  _mergers: [
    require("./_merger").copy source: "states"
    ]
  mixins: [
    require "./computed"
  ]
  methods:
    $states: (name,states) ->
      @[name] = o = (newState, value) ->
        if o._state
          value ?= o[o._state]
          o[o._state] = false
        value ?= true
        o._state = newState
        o[newState] = value
        o._value = value if o._value != value
      @$watch.path(parent:o, path: name+"._state")
      @$watch.path(parent:o, path: name+"._value")
      for k, v of states
        @$watch.path(parent:o, name: k, value:false, path: name+"."+k, cbs:v.cbs, initial: v.initial or false)
        unless (can = v.can)
          if k != "initial"
            can = ((k) -> ~((tmp = states[o._state]).next or tmp).indexOf(k)).bind(null, k)
          else
            can = -> true
        @$computed.parseAndInit can, {parent:o, name:getCan(k), parentPath:name} 
      o("initial")
  connectedCallback: ->
    if @_isFirstConnect
      for k,v of @states
        @$states k, v

        
test module.exports, {
  states:
    test:
      initial: ["1"]
      1: ["2"]
      2: []
}, (el) ->
  it "should have initial state", ->
    el.test.initial.should.be.true
    el.test[1].should.be.false
    el.test[2].should.be.false
  it "should create canVars", ->
    should.exist el.test.canInitial
    should.exist el.test.can1
    should.exist el.test.can2
  it "should give right answers", ->
    el.test.can1.should.not.be.false
    el.test.can2.should.not.be.true
  it "should change state", ->
    el.test(1)
    el.test.initial.should.be.false
    el.test[1].should.be.true
    el.test[2].should.be.false
  it "should give right answers", ->
    el.test.can1.should.not.be.true
    el.test.can2.should.not.be.false