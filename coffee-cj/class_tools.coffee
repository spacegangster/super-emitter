fn = require "vendor/f-empower"

{ clonedeep
  map
  multicall
  union } = fn

delete_key_from_collection = (key, collection) ->
  idx_of_key = (index_of_key_in_collection  key, collection)
  collection.splice(idx_of_key, 1)  if idx_of_key != -1

index_of_key_in_collection = (key, collection) ->
  (fn.index_of key, (map '0', collection))

name_isnt_reserved = (member_name) ->
  !(member_name in ['blueprint', 'event_table'])

to_objects_array = (mixins) ->
  for mixin_entry in mixins
    (('function' is typeof mixin_entry) && mixin_entry.prototype) || mixin_entry

merge_blueprints = (blueprints...) ->
  blueprints = (clonedeep blueprints)
  resulting_blueprint = blueprints.shift()
  
  for source_blueprint in blueprints
    for row in source_blueprint
      [ part_name, part_conf ] = row
      delete_key_from_collection(part_name, resulting_blueprint)
      resulting_blueprint.push(row)
  
  resulting_blueprint

merge_partial_initializers = (mixins) ->
  (multicall (map 'partial_init', mixins))

merge_event_tables = (tables...) ->
  resulting_table = []
  index_of = index_of_key_in_collection
  for source_table in tables
    # 1 Merging emitters
    for [ semitter, sevents ] in source_table
      remitter_idx = (index_of semitter, resulting_table)
      remitter_row = null
      revents      = null
      if remitter_idx == -1
        revents = []
        remitter_row = [ semitter, revents ]
        resulting_table.push(remitter_row)
      else
        [ remitter, revents ] = resulting_table[remitter_idx]

    # 2 Merging events
      for [ sevent, sreactions ] in sevents
        revent_idx = (index_of sevent, revents)
        if revent_idx == -1
          revent_row = [sevent, sreactions]
          revents.push(revent_row)
        else
          revent_row = revents[revent_idx]
          revent_row[1] = (union revent_row[1], sreactions)

  resulting_table

# @return a class that mixes methods from 
mix_of = (Base, mixins...) ->
  mixins = (to_objects_array mixins)
  class Mixed extends Base
  mix_proto = Mixed.prototype

  for mixin in mixins
    for member_name, member of mixin when (name_isnt_reserved member_name)
      mix_proto[member_name] = member

  mixins.unshift(Base.prototype)
  Mixed::partial_init = merge_partial_initializers( mixins )
  Mixed

{ merge_blueprints
, merge_events: merge_event_tables
, merge_event_tables
, merge_partial_initializers
, mix_of }
