// Generated by atdd from type definitions in %s.

// This implements classes for the types defined in '%s', providing
// methods and functions to convert data from/to JSON.

// ############################################################################
// # Private functions
// ############################################################################

import std.algorithm : map;
import std.array : array;
import std.conv;
import std.format;
import std.functional;
import std.json;
import std.sumtype;
import std.typecons : nullable, Nullable, tuple, Tuple;

class AtdException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

void _atd_missing_json_field(string typeName, string jsonFieldName)
{
    throw new AtdException("missing field %s in JSON object of type %s".format(typeName, jsonFieldName));
}

// TODO check later if template is right way to go
AtdException _atd_bad_json(T)(string expectedType, T jsonValue)
{
    string valueStr = jsonValue.to!string;
    if (valueStr.length > 200)
    {
        valueStr = valueStr[0 .. 200];
    }

    return new AtdException(
        "incompatible JSON value where type '%s' was expected: %s".format(
            expectedType, valueStr
    ));
}

AtdException _atd_bad_d(T)(string expectedType, T jsonValue)
{
    string valueStr = jsonValue.to!string;
    if (valueStr.length > 200)
    {
        valueStr = valueStr[0 .. 200];
    }

    return new AtdException(
        "incompatible D value where type '%s' was expected: %s".format(
            expectedType, valueStr
    ));
}

typeof(null) _atd_read_unit(JSONValue x)
{
    if (x.isNull)
        return null;
    else
        throw _atd_bad_json("unit", x);
}

bool _atd_read_bool(JSONValue x)
{
    try
        return x.boolean;
    catch (JSONException e)
        throw _atd_bad_json("bool", x);
}

int _atd_read_int(JSONValue x)
{
    try
        return cast(int) x.integer;
    catch (JSONException e)
        throw _atd_bad_json("int", x);
}

float _atd_read_float(JSONValue x)
{
    try
        return x.floating;
    catch (JSONException e)
        throw _atd_bad_json("float", x);
}

string _atd_read_string(JSONValue x)
{
    try
        return x.str;
    catch (JSONException e)
        throw _atd_bad_json("string", x);
}

auto _atd_read_list(T)(T delegate(JSONValue) readElements)
{
    return (JSONValue jsonVal) { 
        if (jsonVal.type != JSONType.array)
            throw _atd_bad_json("array", jsonVal);
        auto list = jsonVal.array;
        return array(list.map!readElements()); 
    };
}

auto _atd_read_object_to_assoc_array(V)(
    V delegate(JSONValue) readValue)
{
    auto fun = (JSONValue jsonVal) {
        if (jsonVal.type != JSONType.object)
            throw _atd_bad_json("object", jsonVal);
        V[string] ret;
        foreach (key, val; jsonVal.object)
            ret[key] = readValue(val);
        return ret;
    };
    return fun;
}

auto _atd_read_object_to_tuple_list(T)(
    T delegate(JSONValue) readValue)
{
    auto fun = (JSONValue jsonVal) {
        if (jsonVal.type != JSONType.object)
            throw _atd_bad_json("object", jsonVal);
        auto tupList = new Tuple!(string, T)[](jsonVal.object.length);
        int i = 0;
        foreach (key, val; jsonVal.object)
            tupList[i++] = tuple(key, readValue(val));
        return tupList;
    };
    return fun;
}

// TODO probably need to change that
auto _atd_read_nullable(T)(T delegate(JSONValue) readElm)
{
    auto fun = (JSONValue e) {
        if (e.isNull)
            return Nullable!T.init;
        else
            return Nullable!T(readElm(e));
    };
    return fun;
}

// this whole set of function could be remplaced by one templated _atd_write_value function
// not sure it is what we want though

JSONValue _atd_write_unit(typeof(null) n)
{
    return JSONValue(null);
}

JSONValue _atd_write_bool(bool b)
{
    return JSONValue(b);
}

JSONValue _atd_write_int(int i)
{
    return JSONValue(i);
}

JSONValue _atd_write_float(float f)
{
    return JSONValue(f);
}

JSONValue _atd_write_string(string s)
{
    return JSONValue(s);
}


auto _atd_write_list(T)(JSONValue delegate(T) writeElm)
{
    return (T[] list) { return JSONValue(array(list.map!writeElm())); };
}

auto _atd_write_assoc_array_to_object(T)(
    JSONValue delegate(T) writeValue)
{
    auto fun = (T[string] assocArr) {
        JSONValue[string] ret;
        foreach (key, val; assocArr)
            ret[key] = writeValue(val);
        return JSONValue(ret);
    };
    return fun;
}

auto _atd_write_tuple_list_to_object(T)(
    JSONValue delegate(T) writeValue)
{
    auto fun = (Tuple!(string, T)[] tupList) {
        JSONValue[string] ret;
        foreach (tup; tupList)
            ret[tup[0]] = writeValue(tup[1]);
        return JSONValue(ret);
    };
    return fun;
}

auto _atd_write_nullable(T)(JSONValue delegate(T) writeElm)
{
    auto fun = (Nullable!T elm) {
        if (elm.isNull)
            return JSONValue(null);
        else
            return writeElm(elm.get);
    };
    return fun;
}

// ======================
// ====== TESTS =========
// ======================


unittest
{
    import std.stdio;
    import std.functional;

    auto l = JSONValue([[1, 2, 3], [4, 5, 6], [7, 8, 9]]);

    auto m = _atd_read_list(_atd_read_list((&_atd_read_int).toDelegate));
    auto mm = _atd_write_list(_atd_write_list((&_atd_write_int).toDelegate));

    assert(l == mm(m(l)));
}

unittest
{
    import std.stdio;

    auto l = JSONValue([JSONValue(1), JSONValue(5)]);

    auto m = _atd_read_list((&_atd_read_int).toDelegate);
    auto mm = _atd_write_list((&_atd_write_int).toDelegate);

    auto read_l = m(l);
    auto write_l = mm(read_l);

    assert(write_l == l);
}

unittest
{
    import std.stdio;

    auto potentiallyNull = JSONValue(null);

    auto m = _atd_read_nullable((&_atd_read_int).toDelegate);
    auto mm = _atd_write_nullable((&_atd_write_int).toDelegate);

    Nullable!int readN = m(potentiallyNull);
    auto writeN = mm(readN);

    assert(potentiallyNull == writeN);
}

unittest
{
    import std.stdio;

    auto notNull = JSONValue(54);

    auto m = _atd_read_nullable((&_atd_read_int).toDelegate);
    auto mm = _atd_write_nullable((&_atd_write_int).toDelegate);

    auto readv = m(notNull);
    auto writev = mm(readv);

    assert(notNull == writev);
}

unittest
{
    import std.stdio;

    auto l = JSONValue([
        "hello": JSONValue(1),
        "there": JSONValue(2),
        "general": JSONValue(3),
        "kenobi": JSONValue(4),
        "haha": JSONValue(5),
    ]);

    auto m = _atd_read_object_to_assoc_array((&_atd_read_int).toDelegate);
    auto mm = _atd_write_assoc_array_to_object((&_atd_write_int).toDelegate);

    auto readv = m(l);
    auto writev = mm(readv);

    assert(writev == l);
}

unittest
{
    import std.stdio;

    auto l = JSONValue([
        "hello": JSONValue(1),
        "there": JSONValue(2),
        "general": JSONValue(3),
        "kenobi": JSONValue(4),
        "haha": JSONValue(5),
    ]);

    auto m = _atd_read_object_to_tuple_list((&_atd_read_int).toDelegate);
    auto mm = _atd_write_tuple_list_to_object((&_atd_write_int).toDelegate);

    auto readv = m(l);
    auto writev = mm(readv);

    assert(writev == l);
}
