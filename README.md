# SuperEmitter
## Event handling and binding
If you are writing your own GUI components, or you are just tired of 
event-binding boilerplate, this package is what you need.
Out of the box:
  Declarative event binding
  Event handling inheritance
  Event handling composition
  Light-weight event emission (no built-in bubble/capture)

### Reader prerequesites
You know CoffeeScript and jQuery.

### Code weirds
```coffeescript
# I use different bracketing to separate method calls from function calls: 
obj.method()
(function1 (function2 arg1), arg2)
# I don't use brackets on methods, if I pass anonymous multiline functions.
$jquery_element.on 'click', (e) ->
  console.log('wow')
```
## How it can change your life:
```coffeescript
# Your old boilerplate to bind handlers to events:
class EventSpaghetti
  constructor: ->
    $some_jquery.on 'click', (e) ->
      task1(e)
      task2(e)
      task3(e)

    @non_jquery_emitter.on 'server_event', (e) ->
      if (event_is_valid e)
        @update_view(e)

new EventSpaghetti();

# Your new boilerplate
class Better extends SuperEmitter
  event_table: [ 
    [ $some_jquery        , [ [ 'click'       , [ task1,
                                                  task2,
                                                  task3          ] ] ] ]
    [ 'non_jquery_emitter', [ [ 'server_event', [ event_is_valid,
                                                  'update_view'  ] ] ] ]
  ]
new Better().bind_events()
```
## Demo
Clone the repo, open demo/index.html in browser, move your mouse,
click on blocks, look at console output.

Read the demo/app.coffee it's very short.

Ask me.

## Docs
Create emitter class, describe its emitters, events and reactions
in `event_table` format:
```coffeescript
# [ [ emitter_name, [ [ event_name, [ reactions... ] ] ] ] ]
# let me show it trough simple composition
# I will write a class descibing a brain of an ancient human.
# It has some methods and should be able to handle various events.

class Brain extends SuperEmitter
  # methods:
  emit_adrenaline: ->
  emit_cortisol: ->
  emit_dopamine: ->
  emit_endorphins: ->
  look_around: ->

ear_events = [ [ 'snake_heard'     , watch_outs     ] ]
eye_events = [ [ 'food_spotted'    , hunt_reactions ]
               [ 'predator_spotted', flee_reactions ] ]


Brain::event_table = [ ear_events, eye_events, nose_events ]
```

## License
### MIT
