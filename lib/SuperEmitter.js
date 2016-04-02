define([
    'vendor/f-empower',
    './class_tools'
], function(fn, ctools) {

    var a_contains  = fn.a_contains,
        a_each      = fn.a_each,
        a_filter    = fn.a_filter,
        bind        = fn.bind,
        each        = fn.each,
        is_array    = fn.is_array,
        is_function = fn.is_function,
        first       = fn.first,
        map         = fn.map,
        not_empty   = fn.not_empty,
        partial     = fn.partial,
        remove_at   = fn.remove_at,
        second      = fn.second,
        slice       = fn.slice,
        vals        = fn.vals;

    function a_get(hash_array, row_name) {
        var j, len1, row;
        for (j = 0, len1 = hash_array.length; j < len1; j++) {
            row = hash_array[j];
            if (row[0] === row_name) {
                return row[1];
            }
        }
    }

    function check_not_emitter(obj) {
        if (!(obj.on || obj.addEventListener)) {
            return true;
        } else {
            // console.warn "object is not an Emitter"
            return false;
        }
    }

    function make_action_undefined_exception(action, emitter_name) {
        return new Error("ListeningError: action " + action + " is undefined for " + emitter_name);
        // emitter_listeners = [
        //   [ emitter, [ listener, [ listened_event, [ reactions ] ] ] ]
        // ]
    }

    function listen(emitter, events, this_arg) {
        if (is_array(emitter)) {
            mutate_list(emitter, events, this_arg);
            //
            if (not_empty(emitter)) {
                for (var j = 0, len1 = emitter.length; j < len1; j++) {
                    var item = emitter[j];
                    _listen(item, events, this_arg);
                }
            }
        }
        //
        else {
            _listen(emitter, events, this_arg);
        }
    }

    function _listen(emitter, event_table, this_arg) {
        var action, actions, bound, bounds, event, j, k, len1, len2, ref;
        if (!emitter || (check_not_emitter(emitter))) { return; }
        //
        bounds = this_arg.__bounds__;
        for (j = 0, len1 = event_table.length; j < len1; j++) {
            ref = event_table[j], event = ref[0], actions = ref[1];
            for (k = 0, len2 = actions.length; k < len2; k++) {
                action = actions[k];
                bound = ((typeof action === 'function') && action) || bounds[action] || (bounds[action] = bind(this_arg[action], this_arg));
                if ((typeof action === 'string') && !this_arg[action]) {
                    throw make_action_undefined_exception(action, emitter);
                } else {
                    if (emitter.on) {
                        emitter.on(event, bound);
                    } else {
                        emitter.addEventListener(event, bound);
                    }
                }
            }
        }
    }

    /**
     * Мутирует массив. Подменяет родные методы `push`, `unshift`,
     * `splice` такими которые автоматически устанавливают обработчики
     * на добавленные элементы и снимают их с удалённых элементов.
     */
    function mutate_list(list, events, this_arg) {
        var old_push = list.push,
            old_splice = list.splice,
            old_unshift = list.unshift;
        //
        list.splice = function() {
            var i = arguments.length;
            while (--i > 1) {
                listen(arguments[i], events, this_arg);
            }
            return old_splice.apply(list, arguments);
        };
        //
        list.push = function() {
            var emitter, j, len1;
            for (j = 0, len1 = arguments.length; j < len1; j++) {
                emitter = arguments[j];
                listen(emitter, events, this_arg);
            }
            return old_push.apply(list, arguments);
        };
        //
        list.unshift = function() {
            var emitter, j, len1;
            for (j = 0, len1 = arguments.length; j < len1; j++) {
                emitter = arguments[j];
                listen(emitter, events, this_arg);
            }
            return old_unshift.apply(list, arguments);
        };
    }

    function to_emitter_row(this_arg, arg) {
        var emitter_name = arg[0],
            events = arg[1];
        if ('string' !== typeof emitter_name) {
            console.warn("SuperEmitter/bind_events: in the upcoming versions direct binding will be removed. Please use property binding instead", emitter_name);
            return [emitter_name, events];
        } else {
            return [this_arg[emitter_name], events];
        }
    }

    function _unlisten_component(listener, component, events) {
        var bounds = listener.__bounds__;
        a_each(events, function(arg) {
            var event_handlers_names, event_name;
            event_name = arg[0], event_handlers_names = arg[1];
            a_each(event_handlers_names, function(handler_name) {
                var bounded_handler = is_function(handler_name) ?
                    handler_name :
                    bounds[handler_name];
                if (component.off) {
                    component.off(event_name, bounded_handler);
                } else if (component.removeEventListener) {
                    component.removeEventListener(event_name, bounded_handler);
                } else {
                    console.log("vendor/SuperEmitter._unlisten_component: component is not a listener", component);
                }
            });
        });
    }

    function unlisten_component(listener, component, events) {
        if (is_array(component)) {
            var components_array = component;
            a_each(components_array, function(component) {
                _unlisten_component(listener, component, events);
            });
        } else {
            return _unlisten_component(listener, component, events);
        }
    }

    function unlisten_components(listener, components_with_events) {
        a_each(components_with_events, function(arg) {
            var component = arg[0],
                events = arg[1];
            unlisten_component(listener, component, events);
        });
    }

    var hasProp = {}.hasOwnProperty;

    var SuperEmitter = (function() {
        function SuperEmitter() {
            this.handlers = {};
            this.__bounds__ = {};
            this.self = this; // помогает декларативно описать обработчиков собственных событий
        }

        // СТАТИЧЕСКИЕ ЧЛЕНЫ
        SuperEmitter.transform_events = ctools.transform_events;
        SuperEmitter.merge_events = ctools.merge_events;
        SuperEmitter.merge_mixin = ctools.merge_mixin;

        SuperEmitter.extend = function(descendant_members) {
            function extend(child, parent, more_members) {
                var ctor, key;
                ctor = function() {
                    this.constructor = child;
                };
                hasProp = {}.hasOwnProperty;
                for (key in parent) {
                    if (hasProp.call(parent, key)) {
                        child[key] = parent[key];
                    }
                }
                ctor.prototype = parent.prototype;
                child.prototype = new ctor();
                fn.assign(child.prototype, more_members);
                child.__super__ = parent.prototype;
                child.prototype.__super__ = parent.prototype;
                return child;
            }
            var true_contructor = descendant_members.constructor || function() {
                return true_contructor.__super__.constructor.apply(this, arguments);
            };
            delete descendant_members.constructor;
            return extend(true_contructor, this, descendant_members);
        };

        SuperEmitter.prototype.bind_events = function() {
            var emitter, events, j, len1, ref, ref1;
            if (!this.event_table) {
                console.warn(this.constructor.name + "/bind_events: `event_table` not found");
                return;
                // throw new Error('SuperEmitter/bind_events: `event_table` not found')
            }
            ref = map(partial(to_emitter_row, this), this.event_table);
            for (j = 0, len1 = ref.length; j < len1; j++) {
                ref1 = ref[j], emitter = ref1[0], events = ref1[1];
                listen(emitter, events, this);
            }
        };

        /**
         * Удаляет собственные обработчики с каждого прослушиваемого компонента
         */
        SuperEmitter.prototype.dispose = function() {
            var components_with_events;
            components_with_events = this.get_components_listened();
            unlisten_components(this, components_with_events);
            return this.off();
        };

        SuperEmitter.prototype.get_components_listened = function() {
            var component_names = map(first, this.event_table),
                components = map(this, component_names),
                components_events = map(second, this.event_table),
                components_with_events = map(Array, components, components_events);
            //
            // Убрать оттуда нуллы, которые получаются когда компонент
            // ещё/уже не прописан в данном экземпляре.
            return a_filter(components_with_events, function(cmp_evt_pack) {
                return !!cmp_evt_pack[0];
            });
        };

        /**
         * Emits specified event with given arguments array.
         * I chose the array form to visually separate event emissions
         * from simple method calls.
         * Beware that args array is not cloned.
         * @param {string} event_name
         * @param {array} args
         */
        SuperEmitter.prototype.emit = function(event_name, args) {
            var handlers, i, len, res;
            handlers = this.handlers[event_name];
            if (!handlers) {
                return;
            }
            //
            i = -1;
            res = null;
            len = handlers.length;
            handlers = slice(handlers);
            while (++i < len) {
                res = handlers[i].apply(this, args);
                if (false === res) {
                    return;
                }
            }
        };

        SuperEmitter.prototype.listen = function(emitter_name, emitter) {
            var emitter_events;
            if (!this.event_table) {
                console.warn(this.constructor.name + "/listen " + emitter_name + ": `event_table` not found");
                return;
            }
            emitter = emitter || this[emitter_name];
            if (emitter_events = a_get(this.event_table, emitter_name)) {
                listen(emitter, emitter_events, this);
            }
            return emitter;
        };

        /**
         * Убирает чужие обработчики с себя.
         * By default function removes all handlers from all events.
         * @param {string} event_name if specified, removes handlers of only that event.
         * @param {function} handler if specified, unbinds only that one handler.
         */
        SuperEmitter.prototype.off = function(event_name, handler) {
            var event_handlers, i, ref;
            if (event_name) {
                event_handlers = this.handlers[event_name];
                if (!event_handlers) {
                    return;
                }
                if (!handler) {
                    event_handlers.length = 0;
                } else {
                    i = event_handlers.length;
                    while (--i >= 0) {
                        if (event_handlers[i] === handler) {
                            event_handlers.splice(i, 1);
                        }
                    }
                }
            } else {
                // remove all handlers from all events
                ref = this.handlers;
                for (event_name in ref) {
                    event_handlers = ref[event_name];
                    event_handlers.length = 0;
                }
            }
        };

        /**
         * Binds a handler on the specified event
         */
        SuperEmitter.prototype.on = function(event_name, handler) {
            var handlers;
            handlers = this.handlers;
            handlers[event_name] = handlers[event_name] || [];
            handlers[event_name].push(handler);
        };

        SuperEmitter.prototype.unlisten = function(emitter_name, emitter) {
            var event_table;
            if (!this.event_table) {
                return;
            }
            event_table = a_get(this.event_table, emitter_name);
            if (!event_table) {
                return;
            }
            if (emitter = emitter || this[emitter_name]) {
                unlisten_component(this, emitter, event_table);
            } else {
                console.warn(this.constructor.name + ".unlisten: no emitter#" + emitter_name);
            }
        };

        /**
         * Спец метод. Возврат false останавливает выполнение последующих
         * обработчиков.
         * Осторожно! В случае если у источника события несколько подписчиков
         * их обработчики тоже не исполнятся.
         */
        SuperEmitter.prototype.___ = function() {
            console.info(this.constructor.name + ".___ canceling event");
            return false;
        };

        return SuperEmitter;

    })();

    return SuperEmitter

});
