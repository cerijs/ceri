# ceriJS

You love reusable web-components, but googles polymer just doesn't look right to you?
Then you have come to the right place.

The aim of CeriJS is to make development and maintenance of custom elements v1 as easy as possible.

### Ecosystem
[cerijs](https://github.com/cerijs/) - core and tooling  
[ceri-comps](https://github.com/ceri-comps) - simple components built with ceri  
[ceri-widgets](https://github.com/ceri-widgets) - complex components built with ceri and other ceri-components  

#### Features
- incoperates many concepts of VueJS
- declarative instead of imperative
- not monolithic
- a component only loads what it needs
- endless backwards compatibility, new API is delivered alongside old one
- not limited to help only in "common" use cases
- tooling for building, testing and publishing

[I want to use a component built with ceri](#i-want-to-use-a-component-built-with-ceri)

[I want to build a component with ceri](#i-want-to-build-a-component-with-ceri)

[I want to build a mixin for ceri](#i-want-to-build-a-mixin-for-ceri)

#### When should you want to build a component with ceri?

Lets face it, the API of your framework of love will change - if its vue, react or angular.
Within a single project this is no problem, but as soon as you have several projects with sharing code, maintenance caused by API change can get tedious.

So as a rule of thumb: use ceri if you plan to use your component across projects, if it is project specific, use the framework of the project and keep it homogenous.

## I want to use a component built with ceri

Custom elements aren't widely adopted, yet.
So you have to use the lightweight [custom-element polyfill](https://github.com/WebReflection/document-register-element):
```sh
npm install --save-dev document-register-element
```
then call it somewhere in your app
```js
// always load the polyfill
require("document-register-element")

// load the polyfill only when needed - with the help of webpack
function polyfillCE() {
  require.ensure([], require => {
    require("document-register-element")
    startupApp() // your startup code depending on window.customElements
  },"cePoly")
}
if !window.customElements
  polyfillCE()
else
  startupApp() // your startup code depending on window.customElements
```
To register a component:
```js
// the name should contain at least one hyphen
window.customElements.define("ceri-component", require("ceri-component"))
// and create a element programatically
el = document.createElement("ceri-component")
```
or use it in your markup 
```html
<ceri-component></ceri-component>
```

The native customElements implementation depends on ES6 classes, this requires some setup of webpack when using the UglifyJSPlugin:
```sh
npm install --save-dev uglifyjs-webpack-plugin git://github.com/mishoo/UglifyJS2#harmony
```
then use it in your webpack.config
```coffee
UglifyJSPlugin = require("uglifyjs-webpack-plugin")
plugins: [new UglifyJSPlugin()]
```

## I want to build a component with ceri

- ATTENTION: ALL API IS STILL IN BETA AND CAN CHANGE ANYTIME

### Getting started

first have a look at [ceri-boilerplate](https://github.com/cerijs/ceri-boilerplate)

### Install

```sh
npm install --save-dev ceri
```
### Usage
```coffee
# the wrapper creates a ES6 or ES5 class, depending if the polyfill is loaded, and calls ceri on it
ceri = require "ceri/lib/wrapper"
# the component
module.exports = ceri
  mixins: [
    require "ceri/lib/watch"
    require "ceri/lib/structure"
  ]
  structure: template 1, """
    <div :text="textprop"></div>
    <slot></slot>
    """
  data: ->
    textprop: "someText"
  watch:
    textprop: -> console.log "textprop changed"
```
### Guideline for building a component

- Required style for features should be managed in `style` attributes
- Optional style should be delivered in one or multiple "theme" css files alongside your component
- Use a mixin only if it helps to reduce complexity in your use-case. They don't come for free
- HTMLElement has a lot of properties, try to not conflict with them

### Reactions
All official [reactions](https://developers.google.com/web/fundamentals/getting-started/primers/customelements#reactions) of all mixins will be merged into your component, with exception of `constructor`.

For setup code use `created` instead.
All `created` callbacks will be called in the constructor

### List of mixins
Name | Links| Short description
---: | ---| -------
[class](#class) | [doc](#class) [src](src/class.coffee) | helper functions to interact with element classes
[classes](#classes) | [doc](#classes) [src](src/classes.coffee) | manage the classes of your element structure
[combined](#combined) | [doc](#combined) [src](src/combined.coffee) | helper function to create a computed property which combines a prop, data and computed obj
[computed](#computed) | [doc](#computed) [src](src/computed.coffee) | adds computed property
[events](#events) | [doc](#events) [src](src/events.coffee) | adds basic events management
[path](#path) | [doc](#path) [src](src/path.coffee) | helper functions to move on objects
[props](#props) | [doc](#props) [src](src/props.coffee) | adds props with attributes reflection
[structure](#structure) | [doc](#structure) [src](src/structure.coffee) | adds core element structure creation
[style](#style) | [doc](#style) [src](src/style.coffee) | helper functions to interact with element style
[styles](#styles) | [doc](#styles) [src](src/styles.coffee) | manage the styles of your element structure
[svg](#svg) | [doc](#svg) [src](src/svg.coffee) | adds svg creation to structure
[tests](#tests) | [doc](#tests) [src](src/tests.coffee) | call unit test on ceri-views
[util](#util) | [doc](#util) [src](src/util.coffee) | some basic helper functions
[watch](#watch) | [doc](#watch) [src](src/watch.coffee) | adds reactive data

### List of directives
Name | Links| Short description
---: | ---| -------
[#ref](#ref) | [doc](#ref) [src](src/#structure.coffee) | saves the element on your instance
[#text, :text](#text-text) | [doc](#text-text) [src](src/#structure.coffee) | sets the textContent of the element
[#if](#if) | [doc](#if) [src](src/#if.coffee) | toggle element
[#show](#show) | [doc](#show) [src](src/#show.coffee) | toggle visibility of an element

### Template attributes
Used with structure mixins and template compiler of [ceri-compiler](https://github.com/cerijs/ceri-compiler) or [ceri-loader](https://github.com/cerijs/ceri-loader).
```html
<!-- as expected -->
<div attr="value"></div> 


<!-- binds attr to the reactive prop @propName -->
<div :attr="propName"></div>


<!-- binds the property prop of the div to the reactive prop @propName -->
<div $prop="propName"></div>


<!-- adds an eventListener on the div which will call the fn @fnName-->
<div @click="fnName"></div>
<!-- use capture mode -->
<div @click.capture="fnName"></div>
<!-- only when target == @ -->
<div @click.self="fnName"></div>
<!-- only when not prevented -->
<div @click.notPrevented="fnName"></div>
<!-- call preventDefault() -->
<div @click.prevent="fnName"></div>
<!-- call stopPropagation() -->
<div @click.stop="fnName"></div>
<!-- remove eventListener once it got called -->
<div @click.once="fnName"></div>


<!-- adds an function @focusDiv which will call focus on the div -->
<div ~focus="focusDiv"></div>
<!-- emit an event "focus" instead -->
<div ~focus.event="focusDiv"></div> 
```


### Mixins

#### Class
Helper functions to interact with element classes
```coffee
mixins: [ require("ceri/lib/class") ]
# usage
@$class.set(el, {someClass: true}) # set class on el to "someClass", el defaults to @
@$class.strToObj("someClass") # {someClass: true}
@$class.objToStr({someClass: true}) # "someClass"
@$class.setStr(el, "someClass") # set class on el to "someClass"
```

#### Classes
Manage the classes of multiple elements, imperativly and declerativly
```coffee
mixins: [ require("ceri/lib/classes") ]
# usage with structure & props
props: class: 
  type: String
  name: "_class" #rename prop, as class is already taken on HTMLElement
structure: template(1,"""<div #ref="someDiv"></div>""")
data: -> @classToggled: true
classes:
  this: # to target the instance
    computed: -> someClass: @classToggled # someClass will be removed on @classToggled = false
    data: -> someOtherClass: true # can be accessed: @classes.this.someOtherClass = false
    prop: "_class" # bind to a prop to pass through a user given class
  someDiv: # to target a ref
    data: -> classForSomeDiv: true
```

#### Combined
Helper function to create a computed property which combines a prop, data and computed obj into one.
```coffee
mixins: [ require("ceri/lib/combined") ] # used in classes and styles
# usage
@$combined({
  path: "somePath"
  value:
    someName:
      data: -> # should return object, will be accessible under @somePath.someName
      computed: -> # should return object
      prop: # name of a prop to watch
  parseProp: (propValue) -> # optional, should convert the value to an object
  normalize: (obj) -> # optional, should return a normalized object
  cbFactory: (name) -> [(val) ->
    # name will be "someName"
    # the cbs will be called whenever the combined object changes
  ]
})
```

#### Computed
Used to lazily recompute a value whenever a dependend, reactive value changes
```coffee
mixins: [ require("ceri/lib/computed") ] 
# usage
data: -> someDependency: true
computed:
  # @computed.someData will be updated when @someDependency changes and its getter is called
  someData: ->
    return @someDependency*1
# when a callback is attached, the computed property will be evaluated
# as soon as a dependency changes
# to attach a callback:
@$watch.path path:"computed.someData", initial: true, cbs: [(newVal) ->
  # do something with newVal
  ]
```

#### Events
adds basic events management
```coffee
mixins: [ require("ceri/lib/events") ] 
# usage
events:
  someEvent: (e) -> # attaches an eventListener on @
#to issue a custom event
@$emit el, "someEvent", "someOptions" # el defaults to @
@$emit "someEvent", "someOptions" # options will be accessible on e.detail
```

#### Path
helper functions to move on objects
```coffee
mixins: [ require("ceri/lib/path") ]
# usage
data: -> some: path: true
@$path.toValue(path:"some.path") # {path:"some.path",value:true}
@$path.setValue(path:"some.path",value:false) # @some.path == false
@$path.toNameAndParent(path:"some.path") # {path:"some.path",name:"path",parent:@some}
```

#### Props
adds props with attributes reflection.
```coffee
mixins: [ require("ceri/lib/props") ]
# usage
props:
  someProp: String # will be connected with "some-prop" attribute
  someProp2:
    type: Boolean # will be casted to boolean
    name: "_someProp2" # will be accessible as @_someProp2 instead of @someProp2
  someProp3: Number # will be casted to number
watch:
  someProp: (val, old) -> # props are reactive
```

#### Structure
adds core element structure creation. Looks for directives.
```coffee
mixins: [ require("ceri/lib/structure") ]
# usage
# adds <div attr=value><p></p></div>
# as a child of your custom element
structure: ->
  return @$el "div", {"":{attr:"value"}}, [@$el "p"]
# alternative with ceri-compiler / ceri-loader
structure: template 1, """<div attr=value><p></p></div>"""
```

#### Style
Helper functions to interact with element styles
```coffee
mixins: [ require("ceri/lib/style") ]
# usage
@$style.set(el, {position:"absolute"}) # el defaults to @
@$style.normalize("position") # will find vendor prefixes
@$style.normalizeObj({position:"absolute"}) # normalize all keys
@$style.setNormalized(el, {position:"absolute"}) # same as set, but will not call normalize on obj
```

#### Styles
Manage the styles of multiple elements, imperativly and declerativly
```coffee
mixins: [ require("ceri/lib/styles") ]
# usage with structure & props
props: style: 
  type: String
  name: "_style" #rename prop, as style is already taken on HTMLElement
structure: template(1,"""<div #ref="someDiv"></div>""")
data: -> height: 10
styles:
  this: # to target the instance
    computed: -> height: @height + "px"
    data: -> position: "absolute"  # can be accessed: @styles.this.position = "relative"
    prop: "_style" # bind to a prop to pass through user given style
  someDiv: # to target a ref
    data: -> position: "absolute"
```

#### Svg
adds svg creation to structure
```coffee
mixins: [ require("ceri/lib/svg") ]
# allows this:
structure: template 1, """<svg></svg>"""
```

#### Tests
Unit test within a ceri view. This shouldn't be used in your component.
```coffee
mixins: [ require("ceri/lib/tests") ]
# usage
tests: (el) ->
  describe "your compontent", ->
    it "should exist", ->
      should.exist(el)
```

#### Util
Some basic helper functions
```coffee
mixins: [ require("ceri/lib/util") ]
# usage
@util.noop #empty function
# returns an array wrapping the argument, if it isn't already one
@util.arrayize({}) # [{}]
@util.isString
@util.isArray
@util.isObject
@util.isFunction
@util.isElement
@util.camelize("test-test") # testTest
@util.capitalize("test") # Test
@util.hyphenate("testTest") # test-test
```

#### Watch
Adds reactive data
```coffee
mixins: [ require("ceri/lib/watch") ]
# usage
data: -> someData: true
watch:
  someData: (val,old) -> # will be called when @someData is set
```

### Directives

#### #ref
saves the element on your instance
```coffee
mixins: [ require("ceri/lib/structure") ]
# usage
structure: template 1, """<div #ref="someDiv"></div>"""
# accessible under @someDiv
```

#### #text, :text
sets the textContent of the element
```coffee
mixins: [ require("ceri/lib/structure") ]
# usage
structure: template 1, """<div #text="someText"></div>"""
# will result in <div>someText</div>
# use :text to bind to a reactive var instead
structure: template 1, """<div :text="someText"></div>"""
data: ->
  someText: "content"
# will result in <div>content</div> and will be updated on change of @someText
```

#### #if
toggle an element
```coffee
mixins: [ require("ceri/lib/#if") ]
# usage with structure and watch
structure: template 1, """<div #if=visible></div>"""
data: -> visible: true
```

#### #show
toggle visibility of an element
```coffee
mixins: [ require("ceri/lib/#show") ]
# usage with structure and watch
structure: template 1, """<div #show=visible></div>"""
data: -> visible: true
```


## I want to build a mixin for ceri

All sorts of mixins can be submitted, make sure to include a unit test and a proper documentation.

Try to restrict your mixin to a namespace with the help of `_rebind`.
```coffee
# simple example
module.exports =
  _name: "someMixin"
  _v: 1
  _rebind: "$someMixin"
  mixins: [
    # add the mixins you depend on
    # these will be flattend on runtime
  ]
  methods:
    $someMixin:
      anArray: [] # will be cloned to the instance
      anObject: {} # shallow cloned to the instance
      aFunction: -> # will be bound to the instance

```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
