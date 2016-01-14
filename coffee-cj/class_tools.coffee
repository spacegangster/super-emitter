fn = require "vendor/f-empower"

{ clonedeep
, map
, multicall
, union } = fn


delete_key_from_collection = (key, collection) ->
  idx_of_key = (index_of_key_in_collection  key, collection)
  collection.splice(idx_of_key, 1)  if idx_of_key != -1

index_of_key_in_collection = (key, collection) ->
  (fn.index_of key, (map '0', collection))

get_from_table = (key, table) ->
  idx = (index_of_key_in_collection key, table)
  if idx < 0
    null
  else
    table[idx][1]

name_isnt_reserved = (member_name) ->
  !(member_name in ['blueprint', 'event_table'])

to_objects_array = (mixins) ->
  for mixin_entry in mixins
    (('function' is typeof mixin_entry) && mixin_entry.prototype) || mixin_entry

merge_blueprints = (blueprints...) ->
  blueprints = (clonedeep blueprints)
  resulting_blueprint = blueprints.shift()
  #
  for source_blueprint in blueprints
    for row in source_blueprint
      [ part_name, part_conf ] = row
      delete_key_from_collection(part_name, resulting_blueprint)
      resulting_blueprint.push(row)
  #
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
    #
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
  #
  for mixin in mixins
    for member_name, member of mixin when (name_isnt_reserved member_name)
      mix_proto[member_name] = member
  #
  mixins.unshift(Base.prototype)
  Mixed::partial_init = merge_partial_initializers( mixins )
  Mixed

# Вмешивает примесь с таблицей событий в базовый класс.
# Должна применятся после определения таблицы событий класса (если она у него есть)
merge_mixin_one = (base_proto, mixin) ->
  mixin_et = mixin[ET]
  base_et  = base_proto[ET]
  #
  for member_name, member of mixin
    if mixin_et != member
      base_proto[member_name] = member
  #
  if mixin_et
    if base_et
      base_proto[ET] = (merge_event_tables base_et, mixin_et)
    else
      base_proto[ET] = mixin_et
  #
  base_proto

merge_mixin = (base_class_fn) ->
  base_proto = base_class_fn.prototype
  mixins     = (fn.rest arguments)
  (fn.reduce merge_mixin_one, base_proto, mixins)
  base_class_fn

# Преобразует таблицу событий, чтобы поддерживать событийное наследование
transform_events = (event_table) ->
  for emitter_row in event_table
    [emitter_name, events_pack] = emitter_row
    # 
    # Если значением в строке оказался не массив событий а строка,
    # то это значит что разработчик хочет чтобы события для заданного
    # источника повторяли упомянутый.
    if (fn.is_string events_pack)
      referenced_emitter_name = events_pack
      emitter_row[1] = (get_from_table referenced_emitter_name, event_table)
      #
      if null == emitter_row[1]
        throw new Error("No emitter##{emitter_name} in the event_table")
  #
  event_table


{ merge_blueprints
, merge_events: merge_event_tables
, merge_event_tables
, merge_mixin
, merge_partial_initializers
, mix_of
, transform_events }
