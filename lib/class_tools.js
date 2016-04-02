define([
    'vendor/f-empower'
], function(fn) {

    var slice = [].slice,
        hasProp = {}.hasOwnProperty;

    /**
     * CoffeeScript version of extend function (prototypal inheritance
     */
    function extend(child, parent) {
        for (var key in parent) {
            if (hasProp.call(parent, key))
                child[key] = parent[key];
        }
        function ctor() {
            this.constructor = child;
        }
        ctor.prototype = parent.prototype;
        child.prototype = new ctor();
        child.__super__ = parent.prototype;
        return child;
    }

    var clonedeep = fn.clonedeep,
        map = fn.map,
        multicall = fn.multicall,
        union = fn.union;


    function delete_key_from_collection(key, collection) {
        var idx_of_key;
        idx_of_key = index_of_key_in_collection(key, collection);
        if (idx_of_key !== -1) {
            return collection.splice(idx_of_key, 1);
        }
    }

    function index_of_key_in_collection(key, collection) {
        return fn.index_of(key, map('0', collection));
    }

    function get_from_table(key, table) {
        var idx;
        idx = index_of_key_in_collection(key, table);
        if (idx < 0) {
            return null;
        } else {
            return table[idx][1];
        }
    }

    function name_isnt_reserved(member_name) {
        return !(member_name === 'blueprint' || member_name === 'event_table');
    }

    function to_objects_array(mixins) {
        var i, len, mixin_entry, results;
        results = [];
        for (i = 0, len = mixins.length; i < len; i++) {
            mixin_entry = mixins[i];
            results.push((('function' === typeof mixin_entry) && mixin_entry.prototype) || mixin_entry);
        }
        return results;
    }

    function merge_blueprints() {
        var blueprints = 1 <= arguments.length ? slice.call(arguments, 0) : []
        blueprints = clonedeep(blueprints);
        var resulting_blueprint = blueprints.shift();
        //
        for (var i = 0, len = blueprints.length; i < len; i++) {
            var source_blueprint = blueprints[i];
            for (var j = 0, len1 = source_blueprint.length; j < len1; j++) {
                var row = source_blueprint[j],
                    part_name = row[0],
                    part_conf = row[1];
                delete_key_from_collection(part_name, resulting_blueprint);
                resulting_blueprint.push(row);
            }
        }
        //
        return resulting_blueprint;
    }

    function merge_partial_initializers(mixins) {
        return multicall(map('partial_init', mixins));
    }

    function merge_event_tables() {
        var tables = 1 <= arguments.length ? slice.call(arguments, 0) : [],
            resulting_table = [];
        var index_of = index_of_key_in_collection;
        for (var i = 0, tables_count = tables.length; i < tables_count; i++) {
            // 1 Merging emitters
            var source_table = tables[i];
            for (var j = 0, events_count = source_table.length; j < events_count; j++) {
                var ref = source_table[j],
                    semitter = ref[0],
                    sevents = ref[1],
                    remitter_idx = index_of(semitter, resulting_table),
                    remitter_row = null,
                    revents = null;
                if (remitter_idx === -1) {
                    revents = [];
                    remitter_row = [semitter, revents];
                    resulting_table.push(remitter_row);
                } else {
                    var ref1 = resulting_table[remitter_idx],
                        remitter = ref1[0],
                        revents = ref1[1];
                }
                // 2 Merging events
                for (var k = 0, handlers_count = sevents.length; k < handlers_count; k++) {
                    var ref2 = sevents[k],
                        sevent = ref2[0],
                        sreactions = ref2[1],
                        revent_idx = index_of(sevent, revents);
                    if (revent_idx === -1) {
                        revent_row = [sevent, sreactions];
                        revents.push(revent_row);
                    } else {
                        revent_row = revents[revent_idx];
                        revent_row[1] = union(revent_row[1], sreactions);
                    }
                }
            }
        }
        return resulting_table;
    }

    /**
     * @return {function} a class that mixes methods from the base class
     *  and the prototypes
     */
    function mix_of() {
        var Base = arguments[0],
            mixins = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        mixins = to_objects_array(mixins);
        //
        var Mixed = (function(superClass) {
            extend(Mixed, superClass);

            function Mixed() {
                return Mixed.__super__.constructor.apply(this, arguments);
            }

            return Mixed;

        })(Base);
        //
        var mix_proto = Mixed.prototype;
        for (var i = 0, len = mixins.length; i < len; i++) {
            var mixin = mixins[i];
            for (var member_name in mixin) {
                var member = mixin[member_name];
                if (name_isnt_reserved(member_name)) {
                    mix_proto[member_name] = member;
                }
            }
        }
        mixins.unshift(Base.prototype);
        Mixed.prototype.partial_init = merge_partial_initializers(mixins);
        return Mixed;
    }

    /**
     * Вмешивает примесь с таблицей событий в базовый класс.
     * Должна применятся после определения таблицы событий класса
     * (если она у него есть)
     */
    function merge_mixin_one(base_proto, mixin) {
        var mixin_et = mixin[ET],
            base_et = base_proto[ET];
        //
        var member, member_name;
        for (member_name in mixin) {
            member = mixin[member_name];
            if (mixin_et !== member) {
                base_proto[member_name] = member;
            }
        }
        //
        if (mixin_et) {
            if (base_et) {
                base_proto[ET] = merge_event_tables(base_et, mixin_et);
            } else {
                base_proto[ET] = mixin_et;
            }
        }
        //
        return base_proto;
    }

    function merge_mixin(base_class_fn) {
        var base_proto = base_class_fn.prototype,
            mixins     = fn.rest(arguments);
        fn.reduce(merge_mixin_one, base_proto, mixins);
        return base_class_fn;
    }

    // Преобразует таблицу событий, чтобы поддерживать событийное наследование
    function transform_events(event_table) {
        for (var i = 0, len = event_table.length; i < len; i++) {
            var emitter_row = event_table[i],
                emitter_name = emitter_row[0],
                events_pack = emitter_row[1];
            //
            // Если значением в строке оказался не массив событий а строка,
            // то это значит что разработчик хочет чтобы события для заданного
            // источника повторяли упомянутый.
            if (fn.is_string(events_pack)) {
                var referenced_emitter_name = events_pack;
                emitter_row[1] = get_from_table(referenced_emitter_name, event_table);
                //
                if (null === emitter_row[1]) {
                    throw new Error("No emitter#" + emitter_name + " in the event_table");
                }
            }
        }
        //
        return event_table;
    }

    return {
        merge_blueprints           : merge_blueprints,
        merge_events               : merge_event_tables,
        merge_event_tables         : merge_event_tables,
        merge_mixin                : merge_mixin,
        merge_partial_initializers : merge_partial_initializers,
        mix_of                     : mix_of,
        transform_events           : transform_events
    };
});
