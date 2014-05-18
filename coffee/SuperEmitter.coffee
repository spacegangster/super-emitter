define [
  './Emitter'
  './functions'
], (Emitter, functions) ->

  { bind
    contains
    find_by_first_value_as_key
    map
    partial
    remove_at
    values } = functions


  make_action_undefined_exception = (action, emitter_name) ->
    new Error("ListeningError: action #{action} is undefined for #{emitter_name}")

  listen = (emitter, event_table, this_arg) ->
    return  if !emitter

    bounds = this_arg.__bounds__
    for [event, actions] in event_table
      for action in actions
        bound = ((typeof action == 'function') && action) ||  # action can be a simple function
          bounds[action] ||
          bounds[action] = (bind this_arg[action], this_arg)

        if (typeof action == 'string') && !this_arg[action]
          throw (make_action_undefined_exception action, emitter) emitter.on(event, bound)
    return

  mutate_list = (list, events, this_arg) ->
    old_push   = list.push
    old_splice = list.splice
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
    else if emitter_name.indexOf(':') == -1
      [ this_arg[emitter_name], events ]
    else
      [ jElement_name, find_selector ] = emitter_name.split(':')
      [ this_arg[jElement_name].find(find_selector), events ]

  class SuperEmitter extends Emitter
    constructor: ->
      super()
      this.__bounds__ = {}
      this.self = this  # helps to bind events
      
    bind_events: ->
      for [emitter, events] in (map (partial to_emitter_row, this), @event_table)
        if Array.isArray(emitter)
          (mutate_list emitter, events, this)

          if (emitter.length)
            for item in emitter
              (listen item, events, this)

        else
          (listen emitter, events, this)
      0

    listen: (emitter_name, emitter) ->
      (listen emitter, (find_by_first_value_as_key @event_table, emitter_name), this)
      emitter

    # This removes all reactions of the listener from the handlers hash.
    # @param listener, (an object with @__bounds__ hash, that is filled 
    # with functions).
    remove_listener: (listener) ->
      listener_bounds = (values listener.__bounds__)
      for event_name, handler_bundle of @handlers
        for handler, handler_idx in handler_bundle by -1
          if (contains handler, listener_bounds)
            (remove_at handler_bundle, handler_idx)
      return

  ###
  Performs bindings of event handlers without instance binding.
  All emitters should be objects not strings, and all actions must functions,
  not the method names.
  ###
  SuperEmitter.activate_event_table = (table) ->
  SuperEmitter
