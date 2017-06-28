isArray = Array.isArray
isObject = (obj) -> typeof obj == "object"
isFunction = (obj) -> typeof obj == "function"
h = /([^-])([A-Z])/g
id = 0
module.exports =
  getID: -> return id++
  noop: ->
  assign: Object.assign or (target, sources...) ->
    target = Object(target)
    if sources?
      for source in sources
        for own k,v of source
          target[k] = v
    return target
  merge: (target, sources...) ->
    target = Object(target)
    if sources?
      for source in sources
        for own k,v of source
          target[k] ?= v
  concat: (arr1,arr2) -> Array.prototype.push.apply(arr1, arr2)
  identity: (val) -> return val
  arrayize: (obj) ->
    if isArray(obj)
      return obj
    else unless obj?
      return []
    else
      return [obj]
  isString: (obj) -> typeof obj == "string" or obj instanceof String
  isArray: isArray
  isObject: isObject
  isFunction: isFunction
  isElement: (obj) ->
    if typeof HTMLElement == "object"
      obj instanceof HTMLElement
    else
      obj? and obj.nodeType? == 1 and typeof obj.nodeName? == "string"
  camelize: (str) -> str.replace /-(\w)/g, (_, c) -> if c then c.toUpperCase() else ''
  capitalize: (str) -> str.charAt(0).toUpperCase() + str.slice(1)
  hyphenate: (str) -> str.replace(h, '$1-$2').toLowerCase()
  clone: (o) ->
    cln = {}
    for own k,v of o
      cln[k] = v
    return cln
  rebind: (o) ->
    proto = Object.getPrototypeOf(o)
    unless o.hasOwnProperty("_isCeri")
      proto = Object.getPrototypeOf(proto)
    for key in o._rebind
      unless o.hasOwnProperty(key)
        o1 = proto[key]
        cerror(!isObject(o1),"_rebind must target object: ", key)
        o2 = {}
        Object.defineProperty o, key, __proto__:null, value: o2 
        for k,v of o1
          if isFunction(v)
            o2[k] = v.bind(o)
          else if isArray(v)
            o2[k] = v.slice()
          else if isObject(v) and v?
            o2[k] = {}
            for k2,v2 of v
              o2[k2] = v2
          else
            o2[k] = v

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