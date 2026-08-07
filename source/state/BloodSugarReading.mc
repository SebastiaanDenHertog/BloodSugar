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

import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;

(:glance)
module BloodSugarReading {
    /*
     * Stored reading layout:
     *
     * [
     *     timestamp,
     *     valueMmol,
     *     source,
     *     context,
     *     schemaVersion
     * ]
     */

    const TIME = 0;
    const VALUE_MMOL = 1;
    const SOURCE = 2;
    const CONTEXT = 3;
    const SCHEMA = 4;

    const FIELD_COUNT = 5;
    const CURRENT_SCHEMA = 1;

    const SOURCE_MANUAL = "manual";
    const SOURCE_LIBRE_LINK_UP = "libre_link_up";

    const DEFAULT_SOURCE = SOURCE_MANUAL;
    const DEFAULT_CONTEXT = "none";

    typedef Record as Array<Storage.ValueType>;

    public function create(
        timestamp as Number,
        valueMmol as Float,
        source as String,
        context as String
    ) as Record {
        return (
            [timestamp, valueMmol, source, context, CURRENT_SCHEMA] as Record
        );
    }

    /*
     * Converts an older stored record into the current format.
     *
     * Supported old formats:
     *
     * [time, value]
     * [time, value, source]
     * [time, value, source, context]
     * [time, value, source, context, schema]
     */
    public function normalize(rawValue, historyIndex as Number) as Record? {
        if (!(rawValue instanceof Array)) {
            System.println(
                "History[" +
                    historyIndex +
                    "] invalid: not an array; type=" +
                    describeType(rawValue)
            );

            return null;
        }

        var rawReading = rawValue as Array;
        var fieldCount = rawReading.size();

        System.println(
            "History[" + historyIndex + "] field count=" + fieldCount
        );

        if (fieldCount <= VALUE_MMOL) {
            System.println(
                "History[" + historyIndex + "] invalid: missing time or value"
            );

            return null;
        }

        var timestamp = toTimestamp(rawReading[TIME]);

        var valueMmol = toFloatValue(rawReading[VALUE_MMOL]);

        if (timestamp == null) {
            System.println(
                "History[" +
                    historyIndex +
                    "] invalid timestamp; type=" +
                    describeType(rawReading[TIME])
            );

            return null;
        }

        if (valueMmol == null || (valueMmol as Float) <= 0.0f) {
            System.println(
                "History[" +
                    historyIndex +
                    "] invalid glucose value; type=" +
                    describeType(rawReading[VALUE_MMOL])
            );

            return null;
        }

        var source = DEFAULT_SOURCE;
        var context = DEFAULT_CONTEXT;

        if (fieldCount > SOURCE) {
            if (rawReading[SOURCE] instanceof String) {
                source = rawReading[SOURCE] as String;
            } else {
                System.println(
                    "History[" +
                        historyIndex +
                        "] source replaced; type=" +
                        describeType(rawReading[SOURCE])
                );
            }
        }

        if (fieldCount > CONTEXT) {
            if (rawReading[CONTEXT] instanceof String) {
                context = rawReading[CONTEXT] as String;
            } else {
                System.println(
                    "History[" +
                        historyIndex +
                        "] context replaced; type=" +
                        describeType(rawReading[CONTEXT])
                );
            }
        }

        /*
         * A newer schema must not be interpreted by older code.
         */
        if (fieldCount > SCHEMA) {
            var schema = toTimestamp(rawReading[SCHEMA]);

            if (schema != null && (schema as Number) > CURRENT_SCHEMA) {
                System.println(
                    "History[" + historyIndex + "] unsupported schema=" + schema
                );

                return null;
            }
        }

        return create(timestamp as Number, valueMmol as Float, source, context);
    }

    public function isCurrent(rawValue) as Boolean {
        if (!(rawValue instanceof Array)) {
            return false;
        }

        var reading = rawValue as Array;

        if (reading.size() != FIELD_COUNT) {
            return false;
        }

        if (toTimestamp(reading[TIME]) == null) {
            return false;
        }

        if (toFloatValue(reading[VALUE_MMOL]) == null) {
            return false;
        }

        if (!(reading[SOURCE] instanceof String)) {
            return false;
        }

        if (!(reading[CONTEXT] instanceof String)) {
            return false;
        }

        var schema = toTimestamp(reading[SCHEMA]);

        return schema != null && (schema as Number) == CURRENT_SCHEMA;
    }

    public function getTime(reading as Record) as Number {
        return reading[TIME].toNumber();
    }

    public function getValueMmol(reading as Record) as Float {
        return reading[VALUE_MMOL].toFloat();
    }

    public function getSource(reading as Record) as String {
        return reading[SOURCE].toString();
    }

    public function getContext(reading as Record) as String {
        return reading[CONTEXT].toString();
    }

    function toTimestamp(value) as Number? {
        if (value instanceof Number) {
            return value as Number;
        }

        if (value instanceof Long) {
            return (value as Long).toNumber();
        }

        if (value instanceof Float) {
            return (value as Float).toNumber();
        }

        if (value instanceof Double) {
            return (value as Double).toNumber();
        }

        return null;
    }

    function toFloatValue(value) as Float? {
        if (value instanceof Float) {
            return value as Float;
        }

        if (value instanceof Number) {
            return (value as Number).toFloat();
        }

        if (value instanceof Long) {
            return (value as Long).toFloat();
        }

        if (value instanceof Double) {
            return (value as Double).toFloat();
        }

        return null;
    }

    public function describeType(value) as String {
        if (value == null) {
            return "Null";
        }

        if (value instanceof Array) {
            return "Array";
        }

        if (value instanceof Dictionary) {
            return "Dictionary";
        }

        if (value instanceof String) {
            return "String";
        }

        if (value instanceof Number) {
            return "Number";
        }

        if (value instanceof Long) {
            return "Long";
        }

        if (value instanceof Float) {
            return "Float";
        }

        if (value instanceof Double) {
            return "Double";
        }

        if (value instanceof Boolean) {
            return "Boolean";
        }

        return "Unknown";
    }
}
