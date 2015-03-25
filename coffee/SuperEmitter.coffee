define [
  'vendor/f-empower'
], (
  fn
) ->

  { a_contains
  , a_each
  , bind
  , each
  , is_array
  , is_function
  , first
  , map
  , not_empty
  , partial
  , remove_at
  , second
  , slice
  , vals } = fn

  a_get = (hash_array, row_name) ->
    for row in hash_array
      if row[0] == row_name
        return row[1]
    return

  check_not_emitter = (obj) ->
    if !(obj.on || obj.addEventListener)
      true
    else
      #console.warn "object is not an Emitter"
      false

  make_action_undefined_exception = (action, emitter_name) ->
    new Error("ListeningError: action #{action} is undefined for #{emitter_name}")

  #  emitter_listeners = [
  #    [ emitter, [ [ listener, [ [ listened_event, [ reactions ] ] ] ] ] ]
  #  ]


  listen = (emitter, events, this_arg) ->
    if (is_array emitter)
      (mutate_list emitter, events, this_arg)
      #
      if (not_empty emitter)
        for item in emitter
          (_listen item, events, this_arg)
      #
    else
      (_listen emitter, events, this_arg)

  _listen = (emitter, event_table, this_arg) ->
    return  if !emitter || (check_not_emitter emitter)
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
      #
      console.warn(
        "SuperEmitter/bind_events: in the upcoming versions direct binding
        will be removed. Please use property binding instead", emitter_name
      )
      #
      [ emitter_name, events ]
    else
      [ this_arg[emitter_name], events ]


  _unlisten_component = (listener, component, events) ->
    bounds = listener.__bounds__
    a_each events, ([event_name, event_handlers_names]) ->
      a_each event_handlers_names, (handler_name) ->
        bounded_handler =
          (is_function handler_name) &&
            handler_name ||
            bounds[handler_name]
        component.off(event_name, bounded_handler)

  unlisten_component = (listener, component, events) ->
    if (is_array component)
      components_array = component
      (a_each components_array, (component) ->
        (_unlisten_component listener, component, events))
    else
      (_unlisten_component listener, component, events)


  unlisten_components = (listener, components_with_events) ->
    a_each components_with_events, ([component, events]) ->
      (unlisten_component listener, component, events)



  class SuperEmitter
    constructor: ->
      @handlers   = {}
      @__bounds__ = {}
      @self       = this  # helps to bind events
      
    bind_events: ->
      if !@event_table
        console.warn(
          "SuperEmitter/bind_events: `event_table` not found #{@constructor.name}"
        )
        return
        # throw new Error('SuperEmitter/bind_events: `event_table` not found')

      #
      for [emitter, events] in (map (partial to_emitter_row, this), @event_table)
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

    # Emits specified event with given arguments array.
    # I chose the array form to visually separate event emissions
    # from simple method calls.
    # Beware that args array is not cloned.
    # @param event_name {string}
    # @param args {array}
    emit: (event_name, args) ->
      handlers = @handlers[event_name]
      if !handlers
        return
      #
      i = -1
      res = null
      len = handlers.length
      handlers = (slice handlers)
      while ++i < len
        res = handlers[i].apply(this, args)
        if ((typeof res == 'boolean') && !res)
          return
      return

    listen: (emitter_name, emitter) ->
      if !@event_table
        console.warn(
          "SuperEmitter/listen #{emitter_name}: `event_table` not found #{@constructor.name}"
        )
        return
        # throw new Error('SuperEmitter/bind_events: `event_table` not found')
      #
      emitter = emitter || this[emitter_name]
      #
      if emitter_events = (a_get @event_table, emitter_name)
        (listen emitter, emitter_events, this)
      emitter

    # Unbinds events.
    # By default function removes all handlers from all events.
    # @param {string} event_name if specified, removes handlers of only that event.
    # @param {function} handler if specified, unbinds only that one handler.
    off: (event_name, handler) ->
      if event_name
        event_handlers = @handlers[event_name]
        if !event_handlers
          return
         #throw new Error("No handlers bound for event #{event_name}")
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

    # Binds handler to the specified event
    on: (event_name, handler) ->
      handlers = @handlers
      handlers[event_name] = handlers[event_name] || []
      handlers[event_name].push(handler)
      return

    unlisten: (emitter_name, emitter) ->
      return  if !@event_table
      #
      event_table = (a_get @event_table, emitter_name)
      return  if !event_table
      #
      emitter = emitter || this[emitter_name]
      (unlisten_component this, emitter, event_table)
      return

    # special method, that prevents following handlers from being executed
    ___: ->
      false
