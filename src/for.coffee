{isObject, isString, isArray, noop} = require("./_helpers")

module.exports =
  _name: "for"
  _v: 1
  mixins:[
    require("./computed")
  ]
  methods: 
    $for: ({anchor, template, names, value, computed}) ->
      cerror !names or !isArray(names), "$for called without array of names"
      cerror !value, "$for called without iteratable"
      tmpl = null
      if isString(template)
        @$watch.path path: template, cbs: (fn) ->
          tmpl = fn
          if objs
            for obj in objs
              oldEls = obj._els
              if fn
                newEls = obj._els = fn.call(obj)
                for el in newEls
                  o.el.insertBefore(el, oldEls[0])
              else
                obj._els = []
              for el in oldEls
                el.remove()
      else
        tmpl = template
      getEls = (obj) -> if tmpl then tmpl.call(obj) else []
      objs = []
      valname = names.shift()
      if computed?
        _computed = @$path.resolveValue(computed)
        addComputed = (obj) ->
          obj.$computed.setup(_computed)
      else
        addComputed = noop
      c = @$computed.orWatch value, (value) ->
        if value?
          last = null
          parent = anchor.parentElement
          append = (tmp) ->
            unless tmp._appended
              tmp._appended = true 
              els = tmp._els
              if last? and (__els = objs[last]._els)? and (sibling = __els[0])?
                next = sibling
              else
                next = anchor
              for el in els
                parent.insertBefore(el, next)
          remove = (tmp) ->
            val._appended = false
            for el in tmp._els
              el.remove()
          if isArray(value)
            indexname = names[0] if names[0]
            keyname = names[1] if names[1]
            for val, i in value by -1
              if (tmp = objs[i])?
                if val != tmp[valname]
                  tmp[valname] = val
                if keyname and key != tmp[keyname]
                  tmp[keyname] = ""
                if indexname and i != tmp[indexname]
                  tmp[indexname] = i
              else
                tmp = objs[i] = @_inherit()
                tmp.$watch.path(parent:tmp, name: valname, value: val, path: valname)
                if indexname
                  tmp.$watch.path(parent:tmp, name: indexname, value: i, path: indexname)
                if keyname
                  tmp.$watch.path(parent:tmp, name: keyname, value: "", path: keyname)
                addComputed(tmp)
                tmp._els = getEls(tmp)
              append(tmp)
              last = i
            for val, i in objs
              unless value[i]
                remove(val)
          else
            indexname = names[1] if names[1]
            keyname = names[0] if names[0]
            keys = Object.keys(value)
            for key,i in keys by -1
              val = value[key]
              if (tmp = objs[i])?
                if val != tmp[valname]
                  tmp[valname] = val
                if keyname and key != tmp[keyname]
                  tmp[keyname] = key
                if indexname and i != tmp[indexname]
                  tmp[indexname] = i
              else
                tmp = objs[i] = @_inherit()
                tmp.$watch.path(parent:tmp, name: valname, value: val, path: valname)
                if indexname
                  tmp.$watch.path(parent:tmp, name: indexname, value: i, path: indexname)
                if keyname
                  tmp.$watch.path(parent:tmp, name: keyname, value: key, path: keyname)
                addComputed(tmp)
                tmp._els = getEls(tmp)
              append(tmp)
              last = i
            for val in objs.slice(keys.length)
              remove(val)
      return objs


test module.exports, (merge) ->
  describe "ceri", ->
    describe "for", ->
      el = null
      before (done) -> 
        el = makeEl merge
          mixins: [ require("./structure") ]
          structure: template(1,"""
            <div #ref=anchor></div>
            """)
          data: ->
            test: ["1","2"]
            template: template 1,"""<p :text=value></p>"""
            template2: template 1,"""<p :text.expr=@value+@key+@index></p>"""
        el.$nextTick done
      after -> el.remove()
      it "should work", (done) ->
        el.$for anchor:el.anchor, template:"template", names:["value"], value: "test"
        el.should.have.text "12"
        el.test = 1:2, 3:4
        el.should.have.text "24"
        el.template = -> []
        el.should.have.text ""
        el.$for anchor:el.anchor, template:"template2", names:["value","key","index"], value: "test"
        el.$nextTick ->
          el.should.have.text "210431"
          done()