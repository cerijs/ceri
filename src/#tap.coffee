
module.exports =
  _name: "#tap"
  _v: 1
  mixins: [
    require("./directives")
  ]
  _attrLookup:
    tap: 
      "#": -> console.log @
