/*
MIT License

Copyright (c) 2026 Sebastiaan den Hertog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

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
