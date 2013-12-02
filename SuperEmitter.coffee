define [
  'core/Emitter'
  'lib/lodash'
], (Emitter, lodash) ->

  { bind
    clone
    fbind
    find_by_first_value_as_key
    isArray
    log
    logwrn
    logerr
    map
    once
    partial
    remap
    xbind  } = lodash

  listen = (emitter, event_table, this_arg) ->
    return  if !emitter

    bounds = this_arg.__bounds__
    for [event, reactions] in event_table
      for reaction in reactions
        debugger if reaction is undefined
        bound = ((typeof reaction != 'string') && reaction) ||  # reaction can be a simple function
          bounds[reaction] ||
          bounds[reaction] = (xbind this_arg[reaction], this_arg)

        # DEV
        throw new Error("ListeningError: reaction #{reaction} is undefined for #{emitter.constructor.name}")  if typeof reaction is 'string' && !this_arg[reaction]

        emitter.on(event, bound)
    0

  mutate_list = (list, events, this_arg) ->
    old_splice = list.splice
    list.splice = ->
      i = arguments.length
      while --i > 1
        (listen arguments[i], events, this_arg)
      old_splice.apply(list, arguments)

    old_push = list.push
    list.push = ->
      (listen emitter, events, this_arg) for emitter in arguments
      old_push.apply(list, arguments)

    old_unshift = list.unshift
    list.unshift = ->
      (listen emitter, events, this_arg) for emitter in arguments
      old_unshift.apply(list, arguments)
    0

  to_emitter_row = (this_arg, [ emitter_name, events ]) ->
    if ('string' != typeof emitter_name)
      [ emitter_name, events ]
    else if emitter_name.indexOf(':') is -1
      # TODO comment
      logwrn "#{this_arg.constructor.name} doesn't have #{emitter_name}"  if !this_arg[emitter_name]
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
      for [emitter, events] in (map @event_table, (partial to_emitter_row, this))
        if (isArray emitter)
          (mutate_list emitter, events, this)
        else
          (listen emitter, events, this)
      0

    listen: (emitter_name, emitter) ->
      (listen emitter, (find_by_first_value_as_key @event_table, emitter_name), this)
      emitter
