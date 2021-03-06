{isString, isFunction, concat} = require("./_helpers")
module.exports =
  _name: "parseFunction"
  _v: 1
  mixins: [
    require "./path"
    require "./computed"
  ]
  methods:
    $parseFunction: (value, cb) ->
      if isFunction(value)
        if isFunction(cb)
          return cb.call(@, value)
        else
          return value
      if isString(value)
        splitted = value.replace(")","").split("(")
        path = splitted.shift()
        if hasArgs = (splitted.length > 0)
          args2 = splitted[0].split(",")
          getArgumentsProcessor = (fn) -> (args...) ->
            tmp = args2.map (path) =>
              newPath = path.replace(/[\"']/g,"")
              return newPath if newPath != path # is literal string
              return Number(newPath) unless isNaN(newPath) # is number
              switch newPath
                when "true" then return true # is boolean
                when "false" then return false
                else return @$path.resolveValue(path) # is variable name
            concat tmp, args if args?
            return fn.apply(@, tmp)
        if isFunction(cb)
          return @$computed.orWatch path, (fn, args...) ->
            if hasArgs and fn? and isFunction(fn)
              fn = getArgumentsProcessor.call(@, fn)
            tmp = [fn]
            concat(tmp, args) if args?
            cb.apply @, tmp
        else
          fn = @$path.resolveValue(path)
          if isFunction(fn)
            return getArgumentsProcessor.call(@, fn) if hasArgs 
            return fn
          return null


test module.exports, {}, (el) ->
  it "should work", ->
