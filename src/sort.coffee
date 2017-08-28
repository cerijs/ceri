{isArray, clone, capitalize} = require("./_helpers")
sorting = (field, reverse, cast) -> 
  if cast
    getter = (obj) -> cast(obj[field])
  else
    getter = (obj) -> obj[field]
  return (a,b) -> 
    a = getter(a)
    b = getter(b)
    return reverse * ((a > b) - (b > a)) 
module.exports =
  _name: "sort"
  _v: 1
  _mergers: [
    require("./_merger").concat source: "sort"
    ]
  _rebind: "$sort"
  mixins: [
    require "./computed"
  ]
  methods:
    $sort: 
      init: (o) ->
        @$sort.__s ?= {}
        @$sort.__s[o.name] = o
        o.watcher = @$watch.path parent:o, name: "sortBy", value: o.sortBy
        cSort = @$computed.init get: ->
          fns = o.sortBy.map ([field,reverse,cast]) -> sorting(field,reverse,cast)
          return null if fns.length == 0
          return (a, b) ->
            for fn in fns
              result = fn(a, b)
              return result if result != 0
            return 0
        @$computed.init path: "sort"+capitalize(o.name), get: ->
          result = {}
          for [field, dir] in o.sortBy
            result[field] = dir
          return result
        @$computed.init path: "sort"+capitalize(o.name)+"Symbol", get: ->
          result = {}
          for [field, dir] in o.sortBy
            result[field] = if dir > 0 then '▲' else '▼'
          return result
        @$computed.init path: "sorted"+capitalize(o.name), get: ->
          tmp = @$path.resolveValue(o.name).slice()
          sorter = cSort.getter()
          if sorter
            tmp.sort(sorter)
          else
            tmp
      by: (o) ->
        if (s = @$sort.__s?[o.target])?
          sortBy = s.sortBy
          f = o.field
          for arr,i in sortBy
            [field,direction] = arr
            if field == f
              arr[1] = -1 * direction
              found = i
          unless found?
            if o.add
              sortBy.push [f,1]
              s.watcher.notify()
            else
              s.sortBy = [[f,1]]
          else unless o.add
            s.sortBy = sortBy.splice(found,1)
          else
            s.watcher.notify()
          
  connectedCallback: ->
    if @_isFirstConnect
      for sort in @sort
        for k,v of sort
          v = [v] unless isArray(v[0])
          @$sort.init name: k, sortBy: v
          
              
        
test module.exports, {}, (el) ->
  it "should work", ->
