{isArray} = require("./_helpers")
easing =
  linear: -> (percent) ->  percent
  pow: (param=2) -> (percent) -> Math.pow(percent,param)
  sin: -> (percent) -> (Math.sin((percent + 3 ) * Math.PI / 2) + 1)
  exp: -> (percent) -> Math.exp(percent)
  circ: -> (percent) -> (1 - Math.sqrt(1 - Math.pow(percent,2)))
  back: (s = 1.70158) -> (percent) -> Math.pow(percent,2) * ((s + 1) * percent - s)
step = (o) -> (timestamp) ->
  unless o.stopped
    s = o.el.style
    unless o.start?
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
    transform = []
    for key, val of o.style
      tmp = val[0] + fac * (val[1] - val[0])
      tmp += val[2] if val[2]
      if s[key]?
        s[key] = tmp
      else
        transform.push "#{key}(#{tmp})"
    if transform.length > 0
      s.transform = transform.join " "
    if fac != 1
      requestAnimationFrame o.next
    else
      o.stop(reset: true)
      o.done?(o)
module.exports =
  _name: "animate"
  _v: 1
  methods:
    $cancelAnimation: (o,newO = {}) ->
      if o?
        return o.stop(newO)
      else
        return newO
    $animate: (o) ->
      o.done = o.done.bind(@) if o.done?
      return o.done?() if @__noAnimation
      if o.style
        o.el ?= @
        o.duration ?= 300
        o.delay ?= 0
        o.easing ?= @$ease "in","linear"
        o.next = requestAnimationFrame.bind(null,step(o))
        o.preserve = o._preserve if o._percent and o._preserve?
        if o._style?
          for key, val of o._style
            tmp = val.slice(0).reverse()
            if tmp.length == 3
              tmp.push(tmp.shift())
            o.style[key] = tmp
        setTimeout o.next, o.delay
        @$animations.push o
        o.stop = (obj) =>
          unless o.stopped
            o.stopped = true
            @$animations.splice @$animations.indexOf(o),1
            if obj?
              if obj.reset
                if o.preserve
                  s = o.el.style
                  for key, val of o.preserve
                    s[key] = val
              else
                obj._preserve = o.preserve
                obj._percent = 1 - Math.min(1,(performance.now() - o.start) / o.duration)
                obj._style = o.style
          return obj
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
  created: ->
    @$animations = []
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
