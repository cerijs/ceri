{isObject, isString, isFunction, isArray, noop, clone} = require("./_helpers")
clustersTmpl = template 1, """
  <div :class=_clusterClasses.firstRow #ref=firstRow :style.expr="'height:'+@_frHeight+'px'"></div>
  <div :class=_clusterClasses.lastRow #ref=lastRow :style.expr="'height:'+@_lrHeight+'px'"></div>
"""
clusterTmpl = template 1, """
  <div :class=_clusterClasses.cluster :style.expr="'overflow:hidden;position:relative;height:'+@_clusterHeight+'px'" #ref=_clusterel>
  </div>
"""
module.exports =
  _name: "c-for-clustered"
  _v: 1
  mixins:[
    require("./for")
    require("./if")
    require("./structure")
    require("./detach")
    require("./parseFunction")
    require("./@resize")
  ]
  methods: 
    $clusteredFor: (o) ->
      #cerror !o.container, "$clusteredFor called without a container element"
      loadingName = o.loadingName || "isLoading"
      o.value = "_clusterData"

      o.main = m = @_inherit()
      m.$watch.path(parent:m, path: "_frHeight", value: 0)
      m.$watch.path(parent:m, path: "_lrHeight", value: 0)
      m._clusterClasses = o.classes

      reattachContainer = @$detach(container = o.container)
      settedUp = false
      ready = false
      init = =>
        if settedUp and ready
          init = null
          @$on event: "scroll", el: container, cbs: processScroll, throttled: true
          @$on event: "resize", el: container, delay: true, cbs: ->
            updateClusterHeight()
            updateClusterCount()
            processScroll(true)
        
          getData(0,1)
          .then(setData[0])
          .then(updateRowHeight)
          .then(updateRowCount)
          .then(processScroll)

          reattachContainer()
      for el in clustersTmpl.call(m)
        container.appendChild el
      
      getData = null
      getCount = null
      @$parseFunction o.getData, (fn) -> 
        getData = fn
        if init? and isFunction(fn)
          ready = true
          init()
      @$parseFunction o.getCount, (fn) -> getCount = fn

      o.clusters = clusters = []
      setData = []
      indexName = o.names[1]
      if indexName
        o.names[1] = "_withinIndex"
        o.computed ?= {}
        o.computed[indexName] = -> @_clusterIndex + @_withinIndex
      for i in [0,1,2]
        clusters.push (c = m._inherit())
        c.$watch.path parent:c, path: loadingName, value: 0
        c.$watch.path(parent:c, path: "_clusternr", value: i-1)
        c.$watch.path(parent:c, path: "_clusterHeight", value: 0)
        if indexName
          c.$computed.init parent:c, path: "_clusterIndex", get: -> 
            @_clusternr*clusterSize
        [el] = clusterTmpl.call(c)
        anchor = document.createComment "for-anchor"
        container.insertBefore el, m.lastRow
        el.appendChild(anchor)
        el.style.position = "relative"
        o.anchor = anchor
        {process, scopes} = c.$for o
        setData.push process
        c._setData = process
        c._forScopes = scopes

      rowHeight = 0
      
      updateRowHeight = ->
        if not (rowHeight = o.rowHeight)
          top = Number.MAX_VALUE
          bottom = Number.MIN_VALUE
          els = clusters[0]._forScopes[0]?._els
          if els?
            for el in els
              rect = el.getBoundingClientRect()
              top = Math.min rect.top, top
              bottom = Math.max rect.bottom, bottom
            rowHeight = bottom - top
          else
            rowHeight = 0
        updateClusterHeight()

      clusterSize = 0
      clusterHeight = 0
      updateClusterHeight = ->
        if not (clusterSize = o.clusterSize)
          clusterSize = Math.ceil((container.offsetHeight or 1 )/ rowHeight)
          clusterSize++ if clusterSize % 2 # enforce even rowcount
        clusterHeight = clusterSize * rowHeight

      rowCount = 0
      updateRowCount = ->
        if getCount?
          return getCount().then (count) ->
            rowCount = count
            updateClusterCount()
        else
          rowCount = 0
          updateClusterCount()
      
      clustersCount = 0
      totalHeight = 0
      updateClusterCount = ->
        if rowCount
          clustersCount = Math.ceil(rowCount / clusterSize)
          totalHeight = rowCount * rowHeight


      clusterVisible = -1
      processScroll = (redraw) ->
        if clusterHeight and ((clusterVisible != (clusterVisible = Math.floor(container.scrollTop/clusterHeight+0.5))) or redraw == true)
          top = container.scrollTop
          absNrs = [clusterVisible-1, clusterVisible, clusterVisible+1]
          lr = m.lastRow
          for absNr in absNrs
            c = clusters[(absNr+3)%3]
            if c._clusternr != (c._clusternr = absNr) or redraw == true 
              if absNr > -1 and (!getCount? or absNr < clustersCount)
                start = absNr*clusterSize
                end = start+clusterSize
                end = Math.min end, rowCount if getCount?
                c._clusterHeight = (end-start)*rowHeight
                getData(start, end)
                .then ((c, loadingid, data) ->
                  if c[loadingName] == loadingid
                    c._setData(data)
                    c[loadingName] = 0
                  ).bind(null, c, ++c[loadingName])
              else
                c._setData([])
                c._clusterHeight = 0
                c[loadingName] = 0
            container.insertBefore c._clusterel, lr
          # setting new first row height
          m._frHeight = Math.max(0, (clusterVisible-1)*clusterHeight)
          if getCount?
            # setting new last row height
            m._lrHeight = Math.max(0, totalHeight - (clusterVisible+2)*clusterHeight)
          container.scrollTop = top
      settedUp = true
      init?()
      return o

test module.exports, {
  structure: template(1,"""
    <div #ref=container style="height:400px"></div>
    """)
  data: -> template: template 1,"""<div :text=data></div>"""
}, (el) ->
  it "should work", (done) ->
    el.$clusteredFor 
      container:el.container
      template:"template"
      names:["data"]
      classes:
        firstRow: "firstRow"
        lastRow: "lastRow"
        cluster: "cluster"
      getData: (start, end) -> Promise.resolve(Array.apply(null, Array(end-start)).map (_, i) => return i+start)
      getCount: -> Promise.resolve(10000)
    setTimeout done, 200
    #el.should.have.text "12"
