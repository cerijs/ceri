createSvgElement = (name) ->
  el = document.createElementNS("http://www.w3.org/2000/svg",name)
  if name == "svg"
    el.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:xlink", "http://www.w3.org/1999/xlink")
  return el

svgTags = [
  "svg"
  "animate"
  "circle"
  "clippath"
  "cursor"
  "defs"
  "desc"
  "ellipse"
  "filter"
  "font-face"
  "foreignObject"
  "g"
  "glyph"
  "image"
  "line"
  "marker"
  "mask"
  "missing-glyph"
  "path"
  "pattern"
  "polygon"
  "polyline"
  "rect"
  "switch"
  "symbol"
  "text"
  "textpath"
  "tspan"
  "use"
  "view"
]

lookup = {}
for name in svgTags
  lookup[name] = createSvgElement

module.exports =
  _name: "svg"
  _v: 1
  _elLookup: lookup
  mixins: [
    require "./structure.coffee"
  ]

test module.exports, (merge) ->
  describe "ceri", ->
    describe "svg", ->
      el = null
      before (done) ->
        el = makeEl merge structure: template 1, """<svg></svg>"""
        el.$nextTick done
      after -> el.remove()
      it "should have svg element", ->
        el.should.contain "svg"
        el.children[0].namespaceURI.should.equal "http://www.w3.org/2000/svg"