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

    const SOURCE_BLE = "ble";
    const SOURCE_AGGREGATE = "aggregate";
    const SOURCE_UNKNOWN = "unknown";

    const PACKED_STORAGE_SCHEMA = 1;

    const PACKED_HEADER_SIZE = 1;
    const PACKED_RECORD_SIZE = 7;

    const PACKED_TIME_OFFSET = 0;
    const PACKED_GLUCOSE_OFFSET = 4;
    const PACKED_METADATA_OFFSET = 6;

    const SOURCE_ID_MANUAL = 0;
    const SOURCE_ID_LIBRE_LINK_UP = 1;
    const SOURCE_ID_BLE = 2;
    const SOURCE_ID_AGGREGATE = 3;
    const SOURCE_ID_UNKNOWN = 15;

    const GLUCOSE_SCALE = 100.0f;
    const MAX_PACKED_GLUCOSE = 65535;

    typedef Record as [Number, Float, String, String, Number];

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

    public function createPackedHistory(
        recordCount as Number
    ) as Lang.ByteArray {
        if (recordCount < 0) {
            recordCount = 0;
        }

        var byteCount = PACKED_HEADER_SIZE + recordCount * PACKED_RECORD_SIZE;
        var bytes = new [byteCount]b;
        bytes[0] = PACKED_STORAGE_SCHEMA;
        return bytes;
    }

    public function isPackedHistory(value as Object?) as Boolean {
        if (!(value instanceof Lang.ByteArray)) {
            return false;
        }
        var bytes = value as Lang.ByteArray;
        if (bytes.size() < PACKED_HEADER_SIZE) {
            return false;
        }

        if (bytes[0].toNumber() != PACKED_STORAGE_SCHEMA) {
            return false;
        }

        return (bytes.size() - PACKED_HEADER_SIZE) % PACKED_RECORD_SIZE == 0;
    }

    public function getPackedCount(bytes as Lang.ByteArray) as Number {
        if (!isPackedHistory(bytes)) {
            return 0;
        }

        return (bytes.size() - PACKED_HEADER_SIZE) / PACKED_RECORD_SIZE;
    }

    public function getPackedRecordOffset(index as Number) as Number {
        return PACKED_HEADER_SIZE + index * PACKED_RECORD_SIZE;
    }

    public function canPackValue(valueMmol as Float) as Boolean {
        if (valueMmol <= 0.0f) {
            return false;
        }

        var scaledValue = (valueMmol * GLUCOSE_SCALE + 0.5f).toNumber();
        return scaledValue > 0 && scaledValue <= MAX_PACKED_GLUCOSE;
    }

    public function writePackedRecord(
        bytes as Lang.ByteArray,
        index as Number,
        timestamp as Number,
        valueMmol as Float,
        sourceId as Number,
        contextId as Number
    ) as Boolean {
        var count = getPackedCount(bytes);

        if (
            index < 0 ||
            index >= count ||
            timestamp <= 0 ||
            !canPackValue(valueMmol)
        ) {
            return false;
        }

        var scaledValue = (valueMmol * GLUCOSE_SCALE + 0.5f).toNumber();
        var offset = getPackedRecordOffset(index);
        bytes[offset + PACKED_TIME_OFFSET] = timestamp & 0xff;
        bytes[offset + PACKED_TIME_OFFSET + 1] = (timestamp >> 8) & 0xff;
        bytes[offset + PACKED_TIME_OFFSET + 2] = (timestamp >> 16) & 0xff;
        bytes[offset + PACKED_TIME_OFFSET + 3] = (timestamp >> 24) & 0xff;
        bytes[offset + PACKED_GLUCOSE_OFFSET] = scaledValue & 0xff;
        bytes[offset + PACKED_GLUCOSE_OFFSET + 1] = (scaledValue >> 8) & 0xff;

        bytes[offset + PACKED_METADATA_OFFSET] =
            ((sourceId & 0x0f) << 4) | (contextId & 0x0f);

        return true;
    }

    public function getPackedTime(
        bytes as Lang.ByteArray,
        index as Number
    ) as Number {
        var offset = getPackedRecordOffset(index) + PACKED_TIME_OFFSET;

        return (
            bytes[offset].toNumber() |
            (bytes[offset + 1].toNumber() << 8) |
            (bytes[offset + 2].toNumber() << 16) |
            (bytes[offset + 3].toNumber() << 24)
        );
    }

    public function getPackedValueMmol(
        bytes as Lang.ByteArray,
        index as Number
    ) as Float {
        var offset = getPackedRecordOffset(index) + PACKED_GLUCOSE_OFFSET;
        var scaledValue =
            bytes[offset].toNumber() | (bytes[offset + 1].toNumber() << 8);

        return scaledValue.toFloat() / GLUCOSE_SCALE;
    }

    public function getPackedSourceId(
        bytes as Lang.ByteArray,
        index as Number
    ) as Number {
        var offset = getPackedRecordOffset(index) + PACKED_METADATA_OFFSET;
        return (bytes[offset].toNumber() >> 4) & 0x0f;
    }

    public function getPackedContextId(
        bytes as Lang.ByteArray,
        index as Number
    ) as Number {
        var offset = getPackedRecordOffset(index) + PACKED_METADATA_OFFSET;
        return bytes[offset].toNumber() & 0x0f;
    }

    public function copyPackedRecord(
        source as Lang.ByteArray,
        sourceIndex as Number,
        destination as Lang.ByteArray,
        destinationIndex as Number
    ) as Void {
        var sourceOffset = getPackedRecordOffset(sourceIndex);

        var destinationOffset = getPackedRecordOffset(destinationIndex);

        for (
            var byteIndex = 0;
            byteIndex < PACKED_RECORD_SIZE;
            byteIndex += 1
        ) {
            destination[destinationOffset + byteIndex] =
                source[sourceOffset + byteIndex];
        }
    }

    public function getSourceId(source as String) as Number {
        if (source.equals(SOURCE_MANUAL)) {
            return SOURCE_ID_MANUAL;
        }

        if (source.equals(SOURCE_LIBRE_LINK_UP)) {
            return SOURCE_ID_LIBRE_LINK_UP;
        }

        if (source.equals(SOURCE_BLE)) {
            return SOURCE_ID_BLE;
        }

        if (source.equals(SOURCE_AGGREGATE)) {
            return SOURCE_ID_AGGREGATE;
        }

        return SOURCE_ID_UNKNOWN;
    }

    public function getSourceFromId(sourceId as Number) as String {
        if (sourceId == SOURCE_ID_MANUAL) {
            return SOURCE_MANUAL;
        }

        if (sourceId == SOURCE_ID_LIBRE_LINK_UP) {
            return SOURCE_LIBRE_LINK_UP;
        }

        if (sourceId == SOURCE_ID_BLE) {
            return SOURCE_BLE;
        }

        if (sourceId == SOURCE_ID_AGGREGATE) {
            return SOURCE_AGGREGATE;
        }

        return SOURCE_UNKNOWN;
    }

    public function normalize(
        rawValue as Object?,
        historyIndex as Number
    ) as Record? {
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
        if (
            timestamp == null ||
            (timestamp as Number) <= 0 ||
            valueMmol == null ||
            !canPackValue(valueMmol as Float)
        ) {
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

    public function isCurrent(rawValue as Object?) as Boolean {
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

    function toTimestamp(value as Object?) as Number? {
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

    function toFloatValue(value as Object?) as Float? {
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

    public function describeType(value as Object?) as String {
        if (value == null) {
            return "Null";
        }
        if (value instanceof Lang.ByteArray) {
            return "ByteArray";
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
