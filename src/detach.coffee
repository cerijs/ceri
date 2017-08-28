
module.exports =
  _name: "detach"
  _v: 1
  methods: 
    $detach: (el) ->
      el ?= @
      if (parent = el.parentElement)?
        sibling = el.nextSibling
        parent.removeChild(el)
        return -> parent.insertBefore el, sibling
      return ->


test module.exports, {}, (el) ->
  it "should work", ->
    sibling = document.createElement "div"
    p = el.parentElement
    p.appendChild(sibling)
    attach = el.$detach()
    should.not.exist el.parentElement
    attach()
    el.parentElement.should.equal p
    el.nextSibling.should.equal sibling
    sibling.remove()
