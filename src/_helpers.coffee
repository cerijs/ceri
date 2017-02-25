isArray = Array.isArray
h = /([^-])([A-Z])/g
module.exports =
  noop: ->
  arrayize: (obj) ->
    if isArray(obj)
      return obj
    else if !obj
      return []
    else
      return [obj]
  isString: (obj) -> typeof obj == "string" or obj instanceof String
  isArray: isArray
  isObject: (obj) -> typeof obj == "object"
  isFunction: (obj) -> typeof obj == "function"
  isElement: (obj) ->
    if typeof HTMLElement == "object"
      obj instanceof HTMLElement
    else
      obj? and obj.nodeType? == 1 and typeof obj.nodeName? == "string"
  camelize: (str) -> str.replace /-(\w)/g, (_, c) -> if c then c.toUpperCase() else ''
  capitalize: (str) -> str.charAt(0).toUpperCase() + str.slice(1)
  hyphenate: (str) -> str.replace(h, '$1-$2').toLowerCase()

test {_name:"_helpers"}, ->
  describe "ceri", ->
    describe "_helpers", ->
      it "should camelize", ->
        module.exports.camelize "test-test-test"
        .should.equal "testTestTest"
      it "should capitalize", ->
        module.exports.capitalize "testtesttest"
        .should.equal "Testtesttest"
      it "should hyphenate", ->
        module.exports.hyphenate "testTestTest"
        .should.equal "test-test-test"