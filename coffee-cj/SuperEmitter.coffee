fn = require "vendor/f-empower"

a_get = (hash_array, row_name) ->
  for row in hash_array
    if row[0] == row_name
      return row[1]
  return

{ a_contains
, a_each
, bind
, each
, is_array
, is_function
, first
, map
, partial
, remove_at
, second
, vals } = fn

make_action_undefined_exception = (action, emitter_name) ->
  new Error("ListeningError: action #{action} is undefined for #{emitter_name}")

#  emitter_listeners = [
#    [ emitter, [ [ listener, [ [ listened_event, [ reactions ] ] ] ] ] ]
#  ]

listen = (emitter, event_table, this_arg) ->
  return  if !emitter
  #
  bounds = this_arg.__bounds__
  for [event, actions] in event_table
    for action in actions
      bound = ((typeof action == 'function') && action) ||  # reaction can be a simple function
        bounds[action] ||
        bounds[action] = (bind this_arg[action], this_arg)
      #
      if (typeof action == 'string') && !this_arg[action]
        throw (make_action_undefined_exception action, emitter)
      else
        if emitter.on
          emitter.on(event, bound)
        else
          emitter.addEventListener(event, bound)
  return

mutate_list = (list, events, this_arg) ->
  old_push    = list.push
  old_splice  = list.splice
  old_unshift = list.unshift
  #
  list.splice = ->
    i = arguments.length
    while --i > 1
      (listen arguments[i], events, this_arg)
    old_splice.apply(list, arguments)
  #
  list.push = ->
    for emitter in arguments
      (listen emitter, events, this_arg)
    old_push.apply(list, arguments)
  #
  list.unshift = ->
    for emitter in arguments
      (listen emitter, events, this_arg)
    old_unshift.apply(list, arguments)
  return

to_emitter_row = (this_arg, [ emitter_name, events ]) ->
  if ('string' != typeof emitter_name)
    [ emitter_name, events ]
  else
    [ this_arg[emitter_name], events ]


_unlisten_component = (listener, component, events) ->
  bounds = listener.__bounds__
  a_each events, ([event_name, event_handlers_names]) ->
    a_each event_handlers_names, (handler_name) ->
      bounded_handler = bounds[handler_name]
      component.off(event_name, bounded_handler)


unlisten_components = (listener, components_with_events) ->
  a_each components_with_events, ([component, events]) ->
    if (is_array component)
      components_array = component
      (a_each components_array, (component) ->
        (_unlisten_component listener, component, events))
    else
      (_unlisten_component listener, component, events)



class SuperEmitter
  constructor: ->
    @handlers   = {}
    @__bounds__ = {}
    @self       = this  # helps to bind events
    
  bind_events: ->
    if !@event_table
      throw new Error('SuperEmitter/bind_events: `event_table` not found')
    #
    for [emitter, events] in (map (partial to_emitter_row, this), @event_table)
      if (is_array emitter)
        (mutate_list emitter, events, this)

        if (emitter.length)
          for item in emitter
            (listen item, events, this)

      else
        (listen emitter, events, this)
    return

  # removes own handlers from every listened component
  dispose: ->
    components_with_events = @get_components_listened()
    (unlisten_components this, components_with_events)
    @off()

  get_components_listened: ->
    component_names   = (map first, @event_table)
    components        = (map this, component_names)
    components_events = (map second, @event_table)
    (map Array, components, components_events)

  ###
  Emits specified event with given arguments array.
  I chose the array form to visually separate event emissions
  from simple method calls.
  Beware that args array is not cloned.
  @param event_name {string}
  @param args {array}
  ###
  emit: (event_name, args) ->
    handlers = @handlers[event_name]
    if !handlers
      return
    #
    i = -1
    res = null
    while ++i < hlen = handlers.length
      res = handlers[i].apply(this, args)
      if ((typeof res == 'boolean') && !res)
        return
    return

  listen: (emitter_name, emitter) ->
    (listen emitter, (a_get @event_table, emitter_name), this)
    emitter

  ###
  Unbinds events.
  By default function removes all handlers from all events.
  @param {string} event_name if specified, removes handlers of only that event.
  @param {function} handler if specified, unbinds only that one handler.
  ###
  off: (event_name, handler) ->
    if event_name
      event_handlers = @handlers[event_name]
      if !event_handlers
        throw new Error("No handlers bound for event #{event_name}")
      #
      if !handler
        event_handlers.length = 0
      else
        i = event_handlers.length
        while --i >=0
          if event_handlers[i] == handler
            event_handlers.splice(i, 1)
    else
      # remove all handlers from all events
      for event_name, event_handlers of @handlers
        event_handlers.length = 0
    return

  ###
  Binds handler to the specified event
  ###
  on: (event_name, handler) ->
    handlers = @handlers
    handlers[event_name] = handlers[event_name] || []
    handlers[event_name].push(handler)
    return

  # This removes all reactions of the listener from the handlers hash.
  # @param listener, (an object with @__bounds__ hash, that is filled 
  # with functions).
  remove_listener: (listener) ->
    listener_bounds = (vals listener.__bounds__)
    for event_name, handler_bundle of @handlers
      for handler, handler_idx in handler_bundle by -1
        if (a_contains listener_bounds, handler)
          (remove_at handler_idx, handler_bundle)
    return

  unlisten: (emitter_name, emitter) ->
    event_table = (a_get @event_table, emitter_name)
    bounds = @__bounds__
    for [event_name, events] in event_table
      for reaction in events
        reaction = (is_function reaction) && reaction || bounds[reaction]
        emitter.off(event_name, reaction)
    return

  # special method, that prevents following handlers from being executed
  ___: ->
    false

###
Performs bindings of event handlers without instance binding.
All emitters should be objects not strings, and all actions must functions,
not the method names.
###
SuperEmitter.activate_event_table = (table) ->
SuperEmitter
