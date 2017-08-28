module.exports =
  _name: "tests"
  _prio: -1000
  _v: 1
  methods:
    _registerTests: (obj) ->
      if process.env.NODE_ENV == "test"
        window.ceriTest obj

test module.exports, (merge) ->
  it "should work", ->
