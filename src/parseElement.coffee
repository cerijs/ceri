{isString} = require("./_helpers")
module.exports =
  _name: "parseElement"
  _v: 1
  _rebind: "$parseElement"
  methods:
    $parseElement:
      byObj: (o) -> return o.el = @$parseElement.byString(o.el)
      byString: (el) ->
        if isString(el) 
          ell = if el == "this" then @ else @[el]
          cerror !ell?, "element ",el," not found"
          return ell
        else if el?
          return el
        else
          return @

test module.exports, (merge) ->
  describe "ceri", ->
    describe "parseElement", ->
      el = null
      before (done) ->
        el = makeEl merge {}
        el.$nextTick done
      after -> el.remove()
      it "should work", ->
