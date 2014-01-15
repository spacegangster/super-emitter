wrapper = ->
  class Emitter
    constructor: ->
      @handlers = {}

    ###
    Unbinds events.
    By default function removes all handlers from all events.
    @param {string} event_name if specified, removes handlers of only that event.
    @param {function} handler if specified, unbinds only that one handler.
    ###
    off: (event_name, handler) ->
      if !event_name
        for event_name, event_handlers of @handlers
          event_handlers.length = 0
      else if !handler
        @handlers[event_name].length = 0
      else
        event_handlers = @handlers[event_name]
        i = event_handlers.length
        while --i >=0
          if event_handlers[i] == handler
            event_handlers.splice(i, 1)
      return

    ###
    Binds handler to the specified event
    ###
    on: (event_name, handler) ->
      handlers = @handlers
      handlers[event_name] = handlers[event_name] || []
      handlers[event_name].push(handler)
      return
   
    ###
    Fires specified event with given arguments array.
    I chose the array form to visually separate event emissions
    from simple method calls.
    Beware that args array is not cloned.
    @param event_name {string}
    @param args {array}
    ###
    fire: (event_name, args) ->
      handlers = @handlers[event_name]
      if !handlers
        return

      i = -1
      res = null
      while ++i < hlen = handlers.length
        res = handlers[i].apply(this, args)
        if ((typeof res == 'boolean') && !res)
          return
      return


# AMD loaders support
if (('undefined' != typeof define) && define.amd)
  (define wrapper)
# CommonJS loaders support
else if (('undefined' != typeof module) && module.exports)
  module.exports = wrapper()
