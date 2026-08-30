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

module BloodSugarPackedReading {
    typedef IncomingRecord as [Number, Float, String, String];

    const SOURCE_MANUAL = "manual";
    const SOURCE_LIBRE_LINK_UP = "libre_link_up";
    const SOURCE_DEXCOM = "dexcom";
    const SOURCE_BLE = "ble";
    const SOURCE_AGGREGATE = "aggregate";
    const SOURCE_UNKNOWN = "unknown";
    const DEFAULT_CONTEXT = "none";

    const STORAGE_SCHEMA = 1;
    const HEADER_SIZE = 1;
    const RECORD_SIZE = 7;
    const TIME_OFFSET = 0;
    const GLUCOSE_OFFSET = 4;
    const METADATA_OFFSET = 6;

    const SOURCE_ID_MANUAL = 0;
    const SOURCE_ID_LIBRE_LINK_UP = 1;
    const SOURCE_ID_BLE = 2;
    const SOURCE_ID_AGGREGATE = 3;
    const SOURCE_ID_DEXCOM = 4;
    const SOURCE_ID_UNKNOWN = 15;

    const GLUCOSE_SCALE = 100.0f;
    const MAX_GLUCOSE = 65535;

    function createHistory(recordCount as Number) as Lang.ByteArray {
        if (recordCount < 0) {
            recordCount = 0;
        }
        var bytes = new [HEADER_SIZE + recordCount * RECORD_SIZE]b;
        bytes[0] = STORAGE_SCHEMA;
        return bytes;
    }

    function isHistory(value as Object?) as Boolean {
        if (!(value instanceof Lang.ByteArray)) {
            return false;
        }
        var bytes = value as Lang.ByteArray;
        return bytes.size() >= HEADER_SIZE &&
            bytes[0].toNumber() == STORAGE_SCHEMA &&
            (bytes.size() - HEADER_SIZE) % RECORD_SIZE == 0;
    }

    function getCount(bytes as Lang.ByteArray) as Number {
        return isHistory(bytes)
            ? (bytes.size() - HEADER_SIZE) / RECORD_SIZE
            : 0;
    }

    function getOffset(index as Number) as Number {
        return HEADER_SIZE + index * RECORD_SIZE;
    }

    function canPackValue(valueMmol as Float) as Boolean {
        if (valueMmol <= 0.0f) {
            return false;
        }
        var scaled = (valueMmol * GLUCOSE_SCALE + 0.5f).toNumber();
        return scaled > 0 && scaled <= MAX_GLUCOSE;
    }

    function write(
        bytes as Lang.ByteArray,
        index as Number,
        timestamp as Number,
        valueMmol as Float,
        sourceId as Number,
        contextId as Number
    ) as Boolean {
        if (
            index < 0 ||
            index >= getCount(bytes) ||
            timestamp <= 0 ||
            !canPackValue(valueMmol)
        ) {
            return false;
        }

        var scaled = (valueMmol * GLUCOSE_SCALE + 0.5f).toNumber();
        var offset = getOffset(index);
        bytes[offset + TIME_OFFSET] = timestamp & 0xff;
        bytes[offset + TIME_OFFSET + 1] = (timestamp >> 8) & 0xff;
        bytes[offset + TIME_OFFSET + 2] = (timestamp >> 16) & 0xff;
        bytes[offset + TIME_OFFSET + 3] = (timestamp >> 24) & 0xff;
        bytes[offset + GLUCOSE_OFFSET] = scaled & 0xff;
        bytes[offset + GLUCOSE_OFFSET + 1] = (scaled >> 8) & 0xff;
        bytes[offset + METADATA_OFFSET] =
            ((sourceId & 0x0f) << 4) | (contextId & 0x0f);
        return true;
    }

    function getTime(bytes as Lang.ByteArray, index as Number) as Number {
        var offset = getOffset(index) + TIME_OFFSET;
        return bytes[offset].toNumber() |
            (bytes[offset + 1].toNumber() << 8) |
            (bytes[offset + 2].toNumber() << 16) |
            (bytes[offset + 3].toNumber() << 24);
    }

    function getValueMmol(
        bytes as Lang.ByteArray,
        index as Number
    ) as Float {
        var offset = getOffset(index) + GLUCOSE_OFFSET;
        var scaled =
            bytes[offset].toNumber() | (bytes[offset + 1].toNumber() << 8);
        return scaled.toFloat() / GLUCOSE_SCALE;
    }

    function getSourceIdAt(
        bytes as Lang.ByteArray,
        index as Number
    ) as Number {
        return (bytes[getOffset(index) + METADATA_OFFSET].toNumber() >> 4) &
            0x0f;
    }

    function getContextIdAt(
        bytes as Lang.ByteArray,
        index as Number
    ) as Number {
        return bytes[getOffset(index) + METADATA_OFFSET].toNumber() & 0x0f;
    }

    function copy(
        source as Lang.ByteArray,
        sourceIndex as Number,
        destination as Lang.ByteArray,
        destinationIndex as Number
    ) as Void {
        var sourceOffset = getOffset(sourceIndex);
        var destinationOffset = getOffset(destinationIndex);
        for (var index = 0; index < RECORD_SIZE; index += 1) {
            destination[destinationOffset + index] = source[sourceOffset + index];
        }
    }

    function getSourceId(source as String) as Number {
        if (source == SOURCE_MANUAL) {
            return SOURCE_ID_MANUAL;
        }
        if (source == SOURCE_LIBRE_LINK_UP) {
            return SOURCE_ID_LIBRE_LINK_UP;
        }
        if (source == SOURCE_BLE) {
            return SOURCE_ID_BLE;
        }
        if (source == SOURCE_AGGREGATE) {
            return SOURCE_ID_AGGREGATE;
        }
        if (source == SOURCE_DEXCOM) {
            return SOURCE_ID_DEXCOM;
        }
        return SOURCE_ID_UNKNOWN;
    }

    function getSource(sourceId as Number) as String {
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
        if (sourceId == SOURCE_ID_DEXCOM) {
            return SOURCE_DEXCOM;
        }
        return SOURCE_UNKNOWN;
    }
}
