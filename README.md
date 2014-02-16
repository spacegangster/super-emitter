# SuperEmitter
## Event handling and binding
If you are writing your own GUI components, or you are just tired of 
event-binding boilerplate, this package is what you need.
Out of the box:
- Declarative event binding, with concise format, very clear
about event source, name and its handlers
- Event handling logic is now a data structure (!!), not code
- Event handling inheritance
- Event handling composition
- Light-weight event emission (no built-in bubble/capture),
but with arguments

### Code weirds
```coffeescript
# I use different parentheses styles to separate method calls from function calls: 
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
class Component extends SuperEmitter
  event_table: [ 
    [ $some_jquery        , [ [ 'click'       , [ task1,
                                                  task2,
                                                  task3          ] ] ] ]
    [ 'non_jquery_emitter', [ [ 'server_event', [ event_is_valid,
                                                  'update_view'  ] ] ] ]
  ]
new Component().bind_events()
```
## Demo
Clone the repo, open demo/index.html in browser, move your mouse,
click on blocks, look at console output.

Read the demo/app.coffee it's very short.

Ask me.

## Docs
### Binding events
Create emitter class, describe its emitters, events and reactions
in `event_table` format:
```coffeescript
# [ [ emitter_name, [ [ event_name, [ reactions... ] ] ] ] ]
# let me show it trough simple composition
# I will write a class descibing a brain of an ancient human,
# That should be able to handle various events.

class Brain extends SuperEmitter
  # Events
  event_table: [
    [ 'ear' , [ [ 'snake_heard'     , [ 'emit_adrenaline'
                                        'look_around'        ] ] ] ]
    [ 'eye' , [ [ 'food_spotted'    , [ 'emit_noradrenaline'
                                        'hunt'
                                        'emit_endorphins'    ] ]
                [ 'predator_spotted', [ 'emit_cortisol'
                                        'emit_adrenaline'
                                        'run'                ] ] ] ]
    [ 'nose', [ [ 'food_smelled'    , [ 'look_around'        ] ]
                [ 'blood_smelled'   , [ 'emit_adrenaline'
                                        'look_around'        ] ] ] ]
  ]

  # constructor and instance members
  constructor = ->
    @ear  = new Ear()
    @eye  = new Eye()
    @nose = new Nose()


  # methods:
  emit_adrenaline: ->
  emit_cortisol: ->
  emit_endorphins: ->
  hunt: ->
  look_around: ->

# The event table can be decomposed as following
flee_reactions = [ 'emit_cortisol', 'emit_adrenaline', 'run' ]
hunt_reactions = [ 'emit_noradrenaline', 'hunt', 'emit_endorphins' ]
seek_reactions = [ 'look_around' ]
watch_outs     = [ 'emit_adrenaline', 'look_around' ]

ear_events  = [ [ 'snake_heard'     , watch_outs     ] ]
eye_events  = [ [ 'food_spotted'    , hunt_reactions ]
                [ 'predator_spotted', flee_reactions ] ]
nose_events = [ [ 'food_smelled'    , seek_reactions
                  'blood_smelled'   , watch_outs     ] ]

ear_pack  = [ 'ear' , ear_events  ]
eye_pack  = [ 'eye' , eye_events  ]
nose_pack = [ 'nose', nose_events ]

Brain::event_table = [ ear_pack, eye_pack, nose_pack ]

```

### Emitting events
```coffeescript
# Use in a method
class Brain extends SuperEmitter
  # ... event table and stuff ...
  # simplest form
  emit_adrenaline: ->
    @emit('adrenaline')

  # or with arguments
  emit_adrenaline: (dose_ml = 0.02, delay_ms = 500, noradrenaline = false) ->
    @emit('adrenaline', [dose_ml, delay_ms, noradrenaline])
    # square brackets used to denote arguments from event name
```

### Receiving events
```coffeescript
class Brain extends SuperEmitter
  # the ones called without args
  receive_adrenaline: ->
    console.log arguments.length # -> 0

  # the ones called with args
  receive_adrenaline: (dose_ml, delay_ms, noradrenaline) ->
    console.log arguments
```

### Event handling is data now
And you can do with it anything you can do with data. Equality,
cloning and merging.

### Merging event tables
There is a `class_tools` module, which contains `merge_events`
function. It is a pure function merges two or more event tables 
into one. New items will be added, repeating ones will be 
removed.

```coffeescript
table1 = [ [ 'nose', [ [ 'smell-cheese', [ 'look_around' ] ] ] ]
           [ 'eye' , [ [ 'sought-food' , [ 'grab_item'   ] ] ] ] ]

table2 = [ [ 'nose', [ [ 'smell-cheese', [ 'search_food' ] ] ] ]
           [ 'eye' , [ [ 'sought-food' , [ 'grab_item'
                                           'chew_item'   ] ] ] ] ]

(class_tools.merge_events table1, table2) # -> will produce:
[ [ 'nose', [ [ 'smell-cheese', [ 'look_around'
                                  'search_food' ] ] ] ]
  [ 'eye' , [ [ 'sought-food' , [ 'grab_item'
                                  'chew_item'   ] ] ] ] ]
```

## License
### MIT
