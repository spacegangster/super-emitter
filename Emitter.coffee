define ->
  class Emitter
    constructor: ->
      @handlers = {}

    # Unbinds all event handlers
    # @param event_name if specified -- unbinds only handlers of that event
    # @param handler if specified -- unbinds only that one handler
    off: (event_name, handler) ->
      if !event_name
        (event_handlers.length = 0) for event_name, event_handlers of @handlers
      else if !handler
        @handlers[event_name].length = 0
      else
        event_handlers = @handlers[event_name]
        i = event_handlers.length
        while --i >=0
          return event_handlers.splice(i, 1)  if event_handlers[i] is handler

    on: (event_name, handler) ->
      handlers = @handlers
      
      if handlers[event_name] is undefined
        handlers[event_name] = []

      handlers[event_name].push(handler)
    
    fire: (event_name, args) ->
      handlers = @handlers[event_name]
      return  if handlers is undefined
      i = -1
      res = null
      while ++i < hlen = handlers.length
        res = handlers[i].apply(this, args)
        return  if (typeof res is 'boolean' && !res)
      0
