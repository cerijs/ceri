parseStyleString = (str) ->
  result = {}
  if str?
    for cssprop in str.split(/;(?![^(]*\))/g)
      if cssprop?
        splitted = cssprop.split /:(.+)/
        if splitted.length > 1
          result[splitted[0].trim()] = splitted[1].trim()
  return result

module.exports =
  _name: "styles"
  _v: 1
  _prio: 700
  _mergers: require("./_merger").copy(source: "styles")
  mixins: [
    require("./style")
    require("./combined")
    require "./parseElement"
  ]
  connectedCallback: ->
    if @_isFirstConnect
      @$combined
        path: "styles"
        value: @styles
        parseProp: parseStyleString
        normalize: @$style.normalizeObj
        cbFactory: (name) ->
          el = @$parseElement.byString(name)
          return [(val) -> @$style.setNormalized el, val]


test module.exports, {
  mixins: [
    require("./structure")
    require("./props")
  ]
  structure: template(1,"""
    <div #ref="someDiv"></div>
    """)
  data: -> width: "10px"
  prop:
    style2:
      type: String
  styles:
    this:
      computed: -> width: @width
      data: -> height: "10px"
      prop: "style2"
    someDiv:
      data: -> height: "20px"
}, (el) ->
  it "should work", (done) ->
    el.should.have.attr "style", "width: 10px; height: 10px;"
    el.someDiv.should.have.attr "style", "height: 20px;"
    el.$nextTick ->
      el.style2 = "position: absolute"
      el.styles.this.height = "20px"
      el.should.have.attr "style", "width: 10px; height: 20px; position: absolute;"
      done()
