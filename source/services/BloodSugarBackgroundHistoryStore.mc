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
import Toybox.Time;

module BloodSugarBackgroundHistoryStore {
    const MAX_RETENTION_SECONDS = 180 * 24 * 60 * 60;
    const STANDARD_MAX_POINTS = 3200;
    const COMPACT_MAX_POINTS = 1500;
    const PROP_COMPACT_PROFILE = "compactHistoryProfile";

    function addReadings(
        readings as Array<BloodSugarPackedReading.IncomingRecord>
    ) as Number {
        var history = BloodSugarHistoryStorage.loadPacked();
        if (history == null) {
            var raw = BloodSugarHistoryStorage.readRaw();
            if (raw != null) {
                return -1;
            }
            history = BloodSugarPackedReading.createHistory(0);
        }

        var bytes = history as Lang.ByteArray;
        var valid = [] as Array<BloodSugarPackedReading.IncomingRecord>;
        var cutoff = Time.now().value() - MAX_RETENTION_SECONDS;

        for (var index = 0; index < readings.size(); index += 1) {
            var reading = readings[index];
            if (
                reading[0] < cutoff ||
                !BloodSugarPackedReading.canPackValue(reading[1]) ||
                containsTime(bytes, reading[0]) ||
                arrayContainsTime(valid, reading[0])
            ) {
                continue;
            }
            valid.add(reading);
        }

        if (valid.size() == 0) {
            return 0;
        }

        sortByTime(valid);
        var existingStart = firstIndexAtOrAfter(bytes, cutoff);
        var existingCount = BloodSugarPackedReading.getCount(bytes);
        var mergedCount = existingCount - existingStart + valid.size();
        var maximum = getMaximumPoints();
        var outputCount = mergedCount > maximum ? maximum : mergedCount;
        var skip = mergedCount - outputCount;
        var output = BloodSugarPackedReading.createHistory(outputCount);
        var existingIndex = existingStart;
        var incomingIndex = 0;
        var outputIndex = 0;
        var added = 0;

        while (existingIndex < existingCount || incomingIndex < valid.size()) {
            var useIncoming = existingIndex >= existingCount;
            if (!useIncoming && incomingIndex < valid.size()) {
                useIncoming = valid[incomingIndex][0] <
                    BloodSugarPackedReading.getTime(bytes, existingIndex);
            }

            if (skip > 0) {
                skip -= 1;
            } else if (useIncoming) {
                var incoming = valid[incomingIndex];
                BloodSugarPackedReading.write(
                    output,
                    outputIndex,
                    incoming[0],
                    incoming[1],
                    BloodSugarPackedReading.getSourceId(incoming[2]),
                    0
                );
                outputIndex += 1;
                added += 1;
            } else {
                BloodSugarPackedReading.copy(
                    bytes,
                    existingIndex,
                    output,
                    outputIndex
                );
                outputIndex += 1;
            }

            if (useIncoming) {
                incomingIndex += 1;
            } else {
                existingIndex += 1;
            }
        }

        return BloodSugarHistoryStorage.savePacked(output) ? added : -1;
    }

    function getMaximumPoints() as Number {
        var compact = BloodSugarSharedStorage.readProperty(
            PROP_COMPACT_PROFILE
        );
        return compact == false ? STANDARD_MAX_POINTS : COMPACT_MAX_POINTS;
    }

    function containsTime(
        bytes as Lang.ByteArray,
        timestamp as Number
    ) as Boolean {
        var count = BloodSugarPackedReading.getCount(bytes);
        for (var index = count - 1; index >= 0; index -= 1) {
            var stored = BloodSugarPackedReading.getTime(bytes, index);
            if (stored == timestamp) {
                return true;
            }
            if (stored < timestamp) {
                return false;
            }
        }
        return false;
    }

    function arrayContainsTime(
        readings as Array<BloodSugarPackedReading.IncomingRecord>,
        timestamp as Number
    ) as Boolean {
        for (var index = 0; index < readings.size(); index += 1) {
            if (readings[index][0] == timestamp) {
                return true;
            }
        }
        return false;
    }

    function firstIndexAtOrAfter(
        bytes as Lang.ByteArray,
        timestamp as Number
    ) as Number {
        var count = BloodSugarPackedReading.getCount(bytes);
        for (var index = 0; index < count; index += 1) {
            if (BloodSugarPackedReading.getTime(bytes, index) >= timestamp) {
                return index;
            }
        }
        return count;
    }

    function sortByTime(
        readings as Array<BloodSugarPackedReading.IncomingRecord>
    ) as Void {
        for (var index = 1; index < readings.size(); index += 1) {
            var moving = readings[index];
            var target = index;
            while (target > 0 && readings[target - 1][0] > moving[0]) {
                readings[target] = readings[target - 1];
                target -= 1;
            }
            readings[target] = moving;
        }
    }
}
