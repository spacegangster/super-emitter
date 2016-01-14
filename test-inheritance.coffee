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
