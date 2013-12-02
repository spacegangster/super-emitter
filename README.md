# SuperEmitter - declarative event binding by Ognivo.
If you tired of event-binding spaghetti, this package is what you need.
It offers simple declarative event binding syntax and event composition abilities.
### How it can change your life:
```javascript
// ...
// Plain javascript boilerplate to bind handlers to events:
function EventSpaghetti() {
  $some_jquery.on('click', function(e) {
    task1(e);
    task2(e);
    task3(e);
  });

  this.non_jquery_emitter.on('server_event', function(e) {
    if ( event_is_valid(e) )
      this.update_view(e);
  });
}
new EventSpaghetti();

// ...
// Is equal to:
function Better() {
  SuperEmitter.call(this);
  this.bind_events();
}
_.extend(Better.prototype, SuperEmitter.prototype);
Better.prototype.event_table = [ 
  [ $some_jquery        , [ [ 'click'       , [ task1, task2, task3           ] ] ] ],
  [ 'non_jquery_emitter', [ [ 'server_event', [ event_is_valid, 'update_view' ] ] ] ]
]
new Better();
```
--------------------------------------

### This looks insanely better when used with coffee:
```coffeescript
class MuchBetter extends SuperEmitter
  event_table: [
    [ $some_jquery        , [ [ 'click'       , [ (task1)
                                                  (task2)
                                                  (task3)        ] ] ] ]
    [ 'non_jquery_emitter', [ [ 'server_event', [ (event_is_valid)
                                                  'update_view'  ] ] ] ]
  ]
  constructor: ->
    @bind_events()
new MuchBetter()

# Things became terrific if you have component hierarchy and mixins:
class BetterSquared extends (class_tools.mix_of MuchBetter, RedButton, blur_reactions)
  event_table: (class_tools.merge_events MuchBetter,
    [ [ 'non_jquery_emitter', [ [ 'server_event', [ 'after_update_view' ] ] ] ]
      [ 'emitter_field3'    , [ [ 'event1'      , [ 'delay_blur'        ] ]
                                [ 'event2'      , [ 'toggle_button'
                                                    'fire_blur'         ] ] ] ]
      [ 'self'              , [ [ 'blur'        , [ 'fire_blur'         ] ] ] ] ])
new BetterSquared()
```
