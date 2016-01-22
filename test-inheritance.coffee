requirejs = require('requirejs')

requirejs.config({
  baseUrl: 'lib'
  nodeRequire: require
})

fn = requirejs('vendor/f-empower')
SuperEmitter = requirejs('SuperEmitter')
console.log "testing inheritance"

Snake = SuperEmitter.extend({
  constructor: ->
    @length = 3
    @x = 0
  slip: ->
    @x += @length
})

x = new Snake()

x.__super__

Python = Snake.extend({
  constructor: ->
    @__super__.constructor.call(this)
    @y = 0
  slip: ->
    @__super__.slip.call(this)
    @y += @length
})

p = new Python()


Cobra = Snake.extend({
  slip: ->
    @__super__.slip.call(this)
})

c = new Cobra()

c.slip()


simple_extend = (child, parent) ->
  f = ->
    this.constructor = child
  f.prototype = parent.prototype
  child.prototype = new f()
  child.__super__ = parent.prototype
  child

extend = (child, parent, child_fields) ->
  hasProp = {}.hasOwnProperty
  for key of parent
    if hasProp.call(parent, key)
      child[key] = parent[key]
  #
  f = ->
    this.constructor = child
  f.prototype = parent.prototype
  child.prototype = new f()
  fn.assign(child.prototype, child_fields)
  child.__super__ = parent.prototype
  child.prototype.__super__ = parent.prototype
  child

Planet = ->
  @diameter = 1
  @position = 0
  return
Planet.prototype.spin = ->
  @position += @diameter

Planet.extend = (new_fields) ->
  child = new_fields.constructor || ->
    @__super__.constructor.apply(this, arguments)
  delete new_fields.constructor
  simple_extend(child, this, new_fields)

neptune = new Planet()
neptune.spin()

Earth = ->
  Earth.__super__.constructor.apply(this)
  @temperature = 0
  return

Earth = simple_extend(Earth, Planet)

Earth.prototype.spin = ->
  Earth.__super__.spin.call(this)
  @temperature += 1

e = new Earth()

e instanceof Earth

e instanceof Planet

Venus = Planet.extend({
  spin: ->
    @position += 3
})

v = new Venus()

v.spin()


class P
class E extends P
e1 = new E()

e1 instanceof E

e1 instanceof P
