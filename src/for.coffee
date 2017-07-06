{isObject, isString, isArray, noop, clone} = require("./_helpers")

module.exports =
  _name: "for"
  _v: 1
  mixins:[
    require("./computed")
  ]
  methods: 
    $for: ({anchor, template, names, value, computed, id}) ->
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
          getNext = ->
            return last._start if last?
            return anchor
          appendComments = (tmp) ->
            el = tmp._start ?= document.createComment "for-item-start"
            el2 = tmp._end ?= document.createComment "for-item-end"
            next = getNext()
            parent.insertBefore el, next
            parent.insertBefore el2, next
          append = (tmp) ->
            unless tmp._appended
              tmp._appended = true 
              els = tmp._els
              end = tmp._end
              for el in els
                parent.insertBefore(el, end)
          remove = (tmp) ->
            if tmp._appended
              tmp._appended = false
              els = tmp._els = []
              el = tmp._start.nextSibling
              end = tmp._end
              while el != end
                tmpel = el
                el = el.nextSibling
                els.push tmpel
                tmpel.remove()
          if isArray(value)
            indexname = names[0] if names[0]
            keyname = names[1] if names[1]
            for val, i in value by -1
              #val = clone(val)
              if id?
                for obj, j in objs
                  if i > j and obj? and val[id] == obj[valname][id]
                    objs[j] = objs[i]
                    tmp = objs[i] = obj
                    break
              if tmp? || (tmp = objs[i])?
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
              if tmp._last != i
                remove(tmp)
                appendComments(tmp)
              append(tmp)
              tmp._last = i
              last = tmp
              tmp = null
            for val, i in objs
              unless value[i]
                remove(val)
          else
            indexname = names[1] if names[1]
            keyname = names[0] if names[0]
            keys = Object.keys(value)
            for key,i in keys by -1
              val = value[key]
              if id?
                for obj, j in objs
                  if i > j and obj? and val[id] == obj[valname][id]
                    objs[j] = objs[i]
                    tmp = objs[i] = obj
                    break
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
              if tmp._last != i
                remove(tmp)
                appendComments(tmp)
              append(tmp)
              tmp._last = i
              last = tmp
              tmp = null
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