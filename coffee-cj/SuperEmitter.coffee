Emitter = require "./Emitter"
fn = require "vendor/f-empower"

a_get = (hash_array, row_name) ->
  for row in hash_array
    if row[0] == row_name
      return row[1]
  return

{ a_contains
, bind
, is_array
, is_function
, map
, partial
, remove_at
, vals } = fn

make_action_undefined_exception = (action, emitter_name) ->
  new Error("ListeningError: action #{action} is undefined for #{emitter_name}")

#  emitter_listeners = [
#    [ emitter, [ [ listener, [ [ listened_event, [ reactions ] ] ] ] ] ]
#  ]

listen = (emitter, event_table, this_arg) ->
  return  if !emitter

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
        emitter.on(event, bound)
  return

mutate_list = (list, events, this_arg) ->
  old_push    = list.push
  old_splice  = list.splice
  old_unshift = list.unshift

  list.splice = ->
    i = arguments.length
    while --i > 1
      (listen arguments[i], events, this_arg)
    old_splice.apply(list, arguments)

  list.push = ->
    for emitter in arguments
      (listen emitter, events, this_arg)
    old_push.apply(list, arguments)

  list.unshift = ->
    for emitter in arguments
      (listen emitter, events, this_arg)
    old_unshift.apply(list, arguments)
  0

to_emitter_row = (this_arg, [ emitter_name, events ]) ->
  if ('string' != typeof emitter_name)
    [ emitter_name, events ]
  else
    [ this_arg[emitter_name], events ]

class SuperEmitter extends Emitter
  constructor: ->
    super()
    this.__bounds__ = {}
    this.self = this  # helps to bind events
    
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
    0

  listen: (emitter_name, emitter) ->
    (listen emitter, (a_get @event_table, emitter_name), this)
    emitter

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

###
Performs bindings of event handlers without instance binding.
All emitters should be objects not strings, and all actions must functions,
not the method names.
###
SuperEmitter.activate_event_table = (table) ->
SuperEmitter
