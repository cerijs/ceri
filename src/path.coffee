{isString} = require("./_helpers")
splittedToObjects = (splitted, obj) ->

  return splitted.reduce ((arr, name, i) ->
    arr.push arr[i][name]
    return arr
    ), [obj]

module.exports =
  _name: "path"
  _v: 1
  _rebind: "$path"
  methods:
    $path:
      toValue: (o) ->
        unless o.value?
          if o.parent and o.name
            o.value = o.parent[o.name]
          else
            o.obj ?= @
            o.value = splittedToObjects(o.path.split("."), o.obj).pop()
        return o
      getValue: (path) -> @$path.toValue(path:path).value
      resolveValue: (val) ->
        if isString(val)
          return @$path.getValue(val)
        else
          return val
      setValue: (o) ->
        if o.value?
          @$path.toNameAndParent(o)
          o.parent[o.name] = o.value
      toNameAndParent: (o) ->
        return o if o.name and o.parent
        splitted = o.path.split(".")
        o.obj ?= @
        o.name = splitted.pop()
        o.parent = splittedToObjects(splitted, o.obj).pop()
        return o

test module.exports, (merge) ->
  path = "some.nested.path"
  describe "ceri", ->
    describe "path", ->
      el = null
      before ->
        el = makeEl(merge({methods:some:nested:path:"test"}))
      after -> el.remove()
      it "should convert path to name and parent", ->
        obj = el.$path.toNameAndParent({path:path})
        obj.name.should.equal "path"
        obj.parent.should.equal el.some.nested
      it "should convert path to value", ->
        obj = el.$path.toValue({path:path})
        obj.value.should.equal el.some.nested.path
      it "should set value by path", ->
        obj = el.$path.setValue({path:path,value:"test2"})
        el.some.nested.path.should.equal "test2"
      it "should convert parent and name to value", ->
        obj = el.$path.toNameAndParent({path:path})
        delete obj.path
        obj = el.$path.toValue(obj)
        obj.value.should.equal el.some.nested.path