bind = (fn, this_arg) ->
  ->
    fn.apply(this_arg, arguments)

contains = (queried_item, collection) ->
  for item in collection
    if queried_item == item
      return true
  false

delay = (delay_millis, fn) ->
  setTimeout(fn, delay_millis)

find_by_first_value_as_key = (value, list_of_lists) ->
  KEY_IDX = 0
  VAL_IDX = 1

  for plain_list in list_of_lists
    if plain_list[KEY_IDX] == value
      return plain_list[VAL_IDX]

  return

indexOf = (list, searched_item) ->
  for item, idx in list
    if item == searched_item
      return idx
  -1

invoke = (method_name, list) ->
  for item in list
    item[method_name]()

map = (fn, collection) ->
  for item in collection
    (fn item)

multicall = (functions) ->
  ->
    for fn in functions
      fn.apply(this, arguments)
    return

partial = ->
  fn = arguments[0]
  partial_args = Array::slice.call(arguments, 1)
  ->
    fn.apply( this, partial_args.concat( Array::slice.call(arguments) ) )

pluck = (list, key_name) ->
  for item in list
    item[key_name]

remove_at = (collection, index_to_remove) ->
  collection.splice(index_to_remove, 1)

union = (list1, list2) ->
  result = list1.slice()
  for item in list2
    if (!(contains item, list1))
      result.push(item)
  result

values = (object) ->
  keys = Object.keys(object)
  for key in keys
    object[key]

{ bind
  contains
  delay
  find_by_first_value_as_key
  indexOf
  invoke
  map
  multicall
  partial
  pluck
  remove_at
  union
  values }
