module.exports =
  _name: "util"
  _prio: 0
  _v: 1
  methods:
    util: require("./_helpers")

test module.exports, {}, (el) ->
  it "should expose helpers", ->
    for name in ["noop","arrayize","isString","isArray","isObject","isFunction","isElement","camelize","capitalize","hyphenate"]
      should.exist el.util[name]
