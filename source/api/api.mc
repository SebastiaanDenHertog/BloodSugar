import Toybox.Lang;

module api {
    function getValue(dictionary as Lang.Dictionary, key as String) {
        if (dictionary.hasKey(key) && dictionary[key] != null) {
            return dictionary[key];
        }

        return null;
    }

    function getString(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as String
    ) as String {
        var value = getValue(dictionary, key);

        if (value == null) {
            return fallback;
        }

        return value.toString();
    }

    function getNumber(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Number
    ) as Number {
        var value = getValue(dictionary, key);

        if (value == null) {
            return fallback;
        }

        var numberValue = value.toNumber();

        if (numberValue == null) {
            return fallback;
        }

        return numberValue;
    }

    function getBoolean(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Boolean
    ) as Boolean {
        var value = getValue(dictionary, key);

        if (value == true) {
            return true;
        }

        if (value == false) {
            return false;
        }

        return fallback;
    }

    function getObject(
        dictionary as Lang.Dictionary,
        key as String
    ) as Lang.Dictionary? {
        var value = getValue(dictionary, key);

        if (value instanceof Lang.Dictionary) {
            return value as Lang.Dictionary;
        }

        return null;
    }

    function getArray(
        dictionary as Lang.Dictionary,
        key as String
    ) as Lang.Array? {
        var value = getValue(dictionary, key);

        if (value instanceof Lang.Array) {
            return value as Lang.Array;
        }

        return null;
    }
}
