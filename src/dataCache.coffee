{concat} = require("./_helpers")
module.exports =
  _rebind: "dataCache"
  mixins:[
    require "./props"
  ]
  props:
    chunksize:
      type: Number
      default: 100
  methods:
    getData: -> Promise.resolve([])
    dataCache:
      _val: {}
      _count: null
      _counter: null
      _getter: {}
      update: (index, data) -> @dataCache._val[index] = data
      insert: (count) -> @dataCache.invalidate(@dataCache._count + count)
      invalidate: (count) ->
        dc = @dataCache
        dc._val = {}
        dc._count = count
        dc._getter = {}
        dc._counter = null
      get: (start, end, options) ->
        dc = @dataCache
        chunksize = @chunksize
        gd = @getData
        chunks = [Math.floor(start/chunksize)..Math.floor((end-1)/chunksize)]
        Promise.all chunks.map (chunknr) ->
          return data if (data = dc._val[chunknr])?
          return getter if (getter = dc._getter[chunknr])?
          cStart = chunknr*chunksize
          cEnd = cStart+chunksize
          getter = dc._getter[chunknr] = gd cStart, cEnd, options
          getter.then (data) ->
            if dc._getter[chunknr]?
              delete dc._getter[chunknr]
              return dc._val[chunknr] = data
          return getter
        .then (results) ->
          result = []
          for chunknr, i in chunks
            cStart = chunknr*chunksize
            data = results[i]
            chunkstart = Math.max(start-cStart,0)
            chunkend = Math.min(end-cStart,chunksize)
            concat(result, data.slice(chunkstart,chunkend))
          return result
      count: (options) ->
        if @getCount?
          dc = @dataCache
          return Promise.resolve count if (count = dc._count)?
          return counter if (counter = dc._counter)?
          counter = dc._counter = @getCount(options)
          counter.then (count) ->
            if dc._counter?
              dc._counter = null
              return dc._count = count
          return counter
        return null