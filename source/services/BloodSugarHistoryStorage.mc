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

(:glance)
module BloodSugarHistoryStorage {
    const STORAGE_KEY = "BloodSugarHistory";

    var _cached as Lang.ByteArray? = null;

    function readRaw() as Object? {
        return BloodSugarSharedStorage.readValue(STORAGE_KEY);
    }

    function loadPacked() as Lang.ByteArray? {
        if (_cached != null) {
            return _cached;
        }

        var value;
        try {
            value = readRaw();
        } catch (error) {
            return null;
        }

        if (!BloodSugarPackedReading.isHistory(value)) {
            return null;
        }

        _cached = value as Lang.ByteArray;
        return _cached;
    }

    function savePacked(bytes as Lang.ByteArray) as Boolean {
        try {
            BloodSugarSharedStorage.writeValue(STORAGE_KEY, bytes);
            _cached = bytes;
            return true;
        } catch (error) {
            return false;
        }
    }

    function invalidate() as Void {
        _cached = null;
    }

    function getCount() as Number {
        var bytes = loadPacked();
        return bytes == null
            ? 0
            : BloodSugarPackedReading.getCount(bytes as Lang.ByteArray);
    }

    function getTimeAt(index as Number) as Number? {
        var bytes = loadPacked();
        if (bytes == null) {
            return null;
        }
        var count = BloodSugarPackedReading.getCount(bytes as Lang.ByteArray);
        return index >= 0 && index < count
            ? BloodSugarPackedReading.getTime(bytes as Lang.ByteArray, index)
            : null;
    }

    function getValueMmolAt(index as Number) as Float? {
        var bytes = loadPacked();
        if (bytes == null) {
            return null;
        }
        var count = BloodSugarPackedReading.getCount(bytes as Lang.ByteArray);
        return index >= 0 && index < count
            ? BloodSugarPackedReading.getValueMmol(
                  bytes as Lang.ByteArray,
                  index
              )
            : null;
    }
}
