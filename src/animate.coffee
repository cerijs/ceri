{isArray} = require("./_helpers")
easing =
  linear: -> (percent) ->  percent
  pow: (param=2) -> (percent) -> Math.pow(percent,param)
  sin: -> (percent) -> (Math.sin((percent + 3 ) * Math.PI / 2) + 1)
  exp: -> (percent) -> Math.exp(percent)
  circ: -> (percent) -> (1 - Math.sqrt(1 - Math.pow(percent,2)))
  back: (s = 1.70158) -> (percent) -> Math.pow(percent,2) * ((s + 1) * percent - s)
processStyle = (style, aniStyle, fac, preserve) ->
  transform = []
  for key, val of aniStyle
    if preserve? and ~preserve.indexOf(key)
      continue
    tmp = val[0] + fac * (val[1] - val[0])
    tmp += val[2] if val[2]
    if style[key]?
      style[key] = tmp
    else
      transform.push "#{key}(#{tmp})"
  if transform.length > 0
    style.transform = transform.join " "
processPreserve = (style, preserve) ->
  if preserve
    for key, val of preserve
      style[key] = val
step = (o) -> (timestamp) ->
  unless o.stopped
    s = o.el.style
    unless o.start?
      o.el.__ceriAnimation = o
      if o._percent
        o.start = timestamp - o._percent * o.duration
      else
        o.start = timestamp
        if o.preserve
          tmp = {}
          for key in o.preserve
            tmp[key] = s[key]
          o.preserve = tmp
        if o.init
          for key, val of o.init
            s[key] = val
    percent = (timestamp - o.start) / o.duration
    if percent > 1
      fac = 1
    else if percent > 0
      fac = o.easing percent
    else
      fac = 0
    processStyle(s,o.style,fac)
    if fac != 1
      requestAnimationFrame o.next
    else
      o.stop?(reset: true)
      o.done?(o)
module.exports =
  _name: "animate"
  _v: 1
  methods:
    $cancelLastandAnimate: (newO) ->
      tmp = @$animations
      if (i = tmp.length) > 0
        newO = @$cancelAnimation(tmp[i-1], newO)
      @$animate newO
    $cancelAnimation: (o,newO = {}) ->
      if o?.stop?
        return o.stop(newO)
      else
        return newO
    $animate: (o) ->
      o.done = o.done.bind(@) if o.done?
      o.el ?= @
      if o.animate == false
        transform = []
        s = o.el.style
        if o.init
          for key, val of o.init
            s[key] = val
        processStyle(s,o.style,1,o.preserve)
        return o.done?() 
      if o.style
        cb = step(o)
        o.duration ?= 300
        o.easing ?= @$ease "in","linear"
        o.next = requestAnimationFrame.bind(null,cb)
        o.preserve = o._preserve if o._percent and o._preserve?
        if o._style?
          for key, val of o._style
            tmp = val.slice(0).reverse()
            if tmp.length == 3
              tmp.push(tmp.shift())
            o.style[key] = tmp
        o.stop = (obj) =>
          unless o.stopped
            o.stopped = true
            @$animations.splice @$animations.indexOf(o),1
            o.el.__ceriAnimation = null
            if obj?
              if obj.reset
                processPreserve(o.el.style,o.preserve)
              else
                percent = Math.min(1,(performance.now() - o.start) / o.duration)
                obj._preserve = o.preserve
                obj._percent = 1 - percent
                obj._value = o.easing(percent)
                obj._style = o.style
          return obj
        o.toEnd = -> o.start = -1e9 unless o.stopped
        if o.delay
          setTimeout o.next, o.delay
        else
          cb(performance.now())
        @$animations.push o
      return o
    $ease: (type, name, param) ->
      fn = easing[name](param)
      return switch type
        when "in" then fn
        when "inOut" then (percent) -> 
          if percent < 0.5
            return 0.5*fn(percent*2)
          else
            return 0.5 + (1 - fn(1 - (percent-0.5)*2))
        when "out" then (percent) -> 1 - fn(1 - percent)
  data: ->
    $animations: []
  destroy: -> 
    for ani in @$animations
      ani.stop()

test module.exports, (merge) ->
  describe "ceri", ->
    describe "animate", ->
      el = null
      before ->
        el = makeEl merge {}
      after -> el.remove()
      it "should work", ->
