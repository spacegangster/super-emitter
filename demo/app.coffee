define [
  'lib/SuperEmitter'
  'lib/functions'
  'lib/jquery'
], (SuperEmitter, functions, jquery) ->

  { bind
    delay
    invoke
    map
    partial } = functions

  delaylong = (partial delay, 2500)
  delaymini = (partial delay, 300)

  create = (ctor, arg) ->
    new ctor(arg)

  class Jelement extends SuperEmitter
    event_table: [
      [ 'self'    , [ [ 'blur'        , [ 'remove_hovered'       ] ] ] ]
      [ '$element', [ [ 'click'       , [ 'add_clicked_title'
                                          'delay_remove_clicked' ] ]
                      [ 'mouseenter'  , [ 'cancel_blur'
                                          'log_hover'
                                          'add_hovered'          ] ]
                      [ 'mouseleave'  , [ 'delay_blur'           ] ] ] ]
    ]
    constructor: (@$element) ->
      super()

    add_hovered: ->
      @$element.addClass('hovered')

    add_clicked_title: ->
      @$element.text('I was clicked')

    delay_blur: ->
      @blur_timeout_id = (delaymini (bind @emit_blur, this))
      console.log('blur delayed', @blur_timeout_id)

    delay_remove_clicked: ->
      delaylong =>
        @$element.text('')

    cancel_blur: ->
      (clearTimeout @blur_timeout_id)
      console.log('blur canceled', @blur_timeout_id)

    emit_blur: ->
      @emit('blur')

    log_hover: ->
      console.log('Mouse is on me')

    remove_hovered: ->
      @$element.removeClass('hovered')

  
  $wraps = (map $, [ '#one', '#two', '#three', '#four'])
  jelements = (map (partial create, Jelement), $wraps)
  (invoke 'bind_events', jelements)
