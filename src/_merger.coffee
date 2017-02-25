{arrayize} = require("./_helpers")
module.exports =
  apply: (obj,mixins,mergers) ->
    mergers = arrayize(mergers)
    mergeInstructions = {}
    mergeFinisher = []
    for merger in mergers
      mergeInstructions[merger.source] = merger.setup(obj.prototype)
      mergeFinisher.push merger.finisher if merger.finisher?
    sortedMixins = mixins.sort (a,b) ->  (b._prio || 0) - (a._prio || 0)
    for mixin in sortedMixins
      for k,v of mergeInstructions
        if mixin[k]?
          v.iterate(mixin[k])
    for k,v of mergeInstructions
      v.end?()
    for finisher in mergeFinisher
      finisher(obj)
    return obj
  copy: (merger) ->
    merger.target ?= merger.source
    merger.setup = (obj) ->
      if merger.target
        obj[merger.target] ?= {}
        target = obj[merger.target]
      else
        target = obj
        if obj[merger.source]?
          for k,v of obj[merger.source]
            obj[k] ?= v
      iterate: (entry) ->
        for k,v of entry
          target[k] ?= v
    return merger
  concat: (merger) ->
    merger.target ?= merger.source
    merger.setup = (obj) ->
      tmp = []
      iterate: (entry) ->
        tmp = tmp.concat(arrayize entry)
      end: ->
        if merger.last
          obj[merger.target] = tmp.concat(arrayize(obj[merger.source]))
        else
          obj[merger.target] = arrayize(obj[merger.source]).concat(tmp)
    return merger

test {_name:"_merger"}, ->
  describe "ceri", ->
    describe "_merger", ->
      it "should copy", (done) ->
        test = class Test
        test.prototype = {}
        module.exports.apply test, [{parent: {a:1,b:1}},{parent: {a:2,c:2}}],
          module.exports.copy source:"parent", finisher: (obj) ->
            o = new obj()
            o.parent.a.should.equal 1
            o.parent.b.should.equal 1
            o.parent.c.should.equal 2
            done()
      it "should concat", (done) ->
        test = class Test
        test.prototype = {}
        module.exports.apply test, [{parent: "test"},{parent: "test2"}],
          module.exports.concat source:"parent", finisher: (obj) ->
            o = new obj()
            o.parent[0].should.equal "test"
            o.parent[1].should.equal "test2"
            done()