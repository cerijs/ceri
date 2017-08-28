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
  "fontFace"
  "foreignObject"
  "g"
  "glyph"
  "image"
  "line"
  "marker"
  "mask"
  "missingGlyph"
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
    require "./structure"
  ]

test module.exports, {
  structure: template 1, """<svg test></svg>"""
}, (el) ->
  it "should have svg element", ->
    el.should.contain "svg[test]"
    el.children[0].namespaceURI.should.equal "http://www.w3.org/2000/svg"