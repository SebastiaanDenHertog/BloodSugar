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

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

(:glance)
module BloodSugarStore {
    const STANDARD_MAX_POINTS = 3200;
    const COMPACT_MAX_POINTS = 1500;

    const SECONDS_PER_HOUR = 60 * 60;
    const SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR;
    const STANDARD_RAW_RETENTION_SECONDS = 7 * SECONDS_PER_DAY;
    const COMPACT_RAW_RETENTION_SECONDS = 3 * SECONDS_PER_DAY;
    const MIDDLE_RETENTION_SECONDS = 30 * SECONDS_PER_DAY;
    const MAX_RETENTION_SECONDS = 180 * SECONDS_PER_DAY;
    const STANDARD_MIDDLE_BUCKET_SECONDS = SECONDS_PER_HOUR;
    const COMPACT_MIDDLE_BUCKET_SECONDS = 2 * SECONDS_PER_HOUR;
    const STANDARD_OLD_BUCKET_SECONDS = 6 * SECONDS_PER_HOUR;
    const COMPACT_OLD_BUCKET_SECONDS = 12 * SECONDS_PER_HOUR;

    const RAW_BUCKET = -1;

    const STORAGE_KEY = "BloodSugarHistory";
    const COMPACT_PROFILE_MEMORY_LIMIT = 128 * 1024;
    const PROP_APP_VERSION = "appVersion";
    const PROP_COMPACT_HISTORY_PROFILE = "compactHistoryProfile";
    const STORAGE_SETUP_DONE = "setupDone";
    const PROP_USE_MGDL = "useMgdl";
    const PROP_USERNAME = "username";
    const PROP_PASSWORD = "password";
    const PROP_BLOOD_MONITOR_INDEX = "bloodMonitorIndex";
    const PROP_CUSTOM_CONTEXTS = "customContexts";

    const PROP_NOTIFICATIONS_ENABLED = "notificationsEnabled";
    const PROP_NOTIFICATION_LOW = "notificationLow";
    const PROP_NOTIFICATION_HIGH = "notificationHigh";

    const PROP_DANGER_LOW = "dangerLow";
    const PROP_LOW = "Low";
    const PROP_HIGH = "High";
    const PROP_DANGER_HIGH = "dangerHigh";

    const PROP_DEFAULT_CONTEXT = "defaultContextIndex";
    const PROP_CONFIRM_SAVE = "confirmBeforeSave";

    // cached items:
    var _useMgdlCache = null;
    var _confirmBeforeSaveCache = null;
    var _defaultContextIndexCache = null;
    var _bloodMonitorCache = null;
    var _notificationsEnabledCache = null;

    var _dangerLowMmolCache = null;
    var _lowMmolCache = null;
    var _highMmolCache = null;
    var _dangerHighMmolCache = null;
    var _notificationLowMmolCache = null;
    var _notificationHighMmolCache = null;

    var _bleSupportedCache = null;
    var _compactHistoryProfileCache = null;

    const NOTIFICATION_NONE = 0;
    const NOTIFICATION_LOW = 1;
    const NOTIFICATION_HIGH = 2;

    const MONITOR_NONE = 0;
    const MONITOR_ABBOTT = 1;
    const MONITOR_BLE = 2;

    var _historyBytes = null;
    var _historyNeedsRepair = false as Boolean;
    var _historyWritable = true;

    function load() {
        if (_historyBytes != null) {
            return _historyBytes;
        }
        var saved = null;

        try {
            saved = Storage.getValue(STORAGE_KEY);
        } catch (error) {
            _historyBytes = BloodSugarReading.createPackedHistory(0);
            _historyWritable = false;
            _historyNeedsRepair = false;
            return _historyBytes;
        }
        if (saved == null) {
            _historyBytes = BloodSugarReading.createPackedHistory(0);
            _historyWritable = true;
            _historyNeedsRepair = false;
            return _historyBytes;
        }
        if (saved instanceof Lang.ByteArray) {
            var bytes = saved as Lang.ByteArray;
            if (!BloodSugarReading.isPackedHistory(bytes)) {
                System.println("Unsupported packed glucose history");
                _historyBytes = BloodSugarReading.createPackedHistory(0);
                _historyWritable = false;
                _historyNeedsRepair = false;
                return _historyBytes;
            }
            _historyBytes = bytes;
            _historyWritable = true;
            _historyNeedsRepair = false;
            var now = Time.now().value();
            if (historyNeedsCompaction(bytes, now)) {
                var compacted = compactPackedHistory(bytes, now);
                _historyBytes = compacted;

                if (savePacked(compacted)) {
                    _historyNeedsRepair = false;
                } else {
                    _historyNeedsRepair = true;
                }
            }
            return _historyBytes;
        }

        if (saved instanceof Array) {
            var migrated = migrateLegacyHistory(saved as Array);
            _historyBytes = migrated;

            _historyWritable = true;

            if (savePacked(migrated)) {
                _historyNeedsRepair = false;
            } else {
                _historyNeedsRepair = true;
            }

            return _historyBytes;
        }

        _historyBytes = BloodSugarReading.createPackedHistory(0);
        _historyWritable = false;
        _historyNeedsRepair = false;
        return _historyBytes;
    }

    function invalidateHistoryCache() as Void {
        _historyBytes = null;
    }

    function migrateLegacyHistory(legacyHistory as Array) as Lang.ByteArray {
        var validCount = 0;

        for (var index = 0; index < legacyHistory.size(); index += 1) {
            var normalized = BloodSugarReading.normalize(
                legacyHistory[index],
                index
            );

            if (
                normalized != null &&
                normalized[BloodSugarReading.TIME].toNumber() > 0 &&
                BloodSugarReading.canPackValue(
                    normalized[BloodSugarReading.VALUE_MMOL].toFloat()
                )
            ) {
                validCount += 1;
            }
        }

        var keepCount = validCount;
        var maximumPoints = getMaximumHistoryPoints();
        if (keepCount > maximumPoints) {
            keepCount = maximumPoints;
        }

        var skipValid = validCount - keepCount;
        var packed = BloodSugarReading.createPackedHistory(keepCount);
        var writeIndex = 0;
        for (
            var legacyIndex = 0;
            legacyIndex < legacyHistory.size();
            legacyIndex += 1
        ) {
            var reading = BloodSugarReading.normalize(
                legacyHistory[legacyIndex],
                legacyIndex
            );

            if (
                reading == null ||
                reading[BloodSugarReading.TIME].toNumber() <= 0 ||
                !BloodSugarReading.canPackValue(
                    reading[BloodSugarReading.VALUE_MMOL].toFloat()
                )
            ) {
                continue;
            }

            if (skipValid > 0) {
                skipValid -= 1;
                continue;
            }

            var source = reading[BloodSugarReading.SOURCE].toString();
            var context = reading[BloodSugarReading.CONTEXT].toString();

            if (
                BloodSugarReading.writePackedRecord(
                    packed,
                    writeIndex,
                    reading[BloodSugarReading.TIME].toNumber(),
                    reading[BloodSugarReading.VALUE_MMOL].toFloat(),
                    BloodSugarReading.getSourceId(source),
                    getContextIndex(context)
                )
            ) {
                writeIndex += 1;
            }
        }

        return packed;
    }

    function historyNeedsRepair() as Boolean {
        load();
        return _historyNeedsRepair;
    }

    function persistHistoryRepair() as Boolean {
        load();
        if (!_historyNeedsRepair) {
            return true;
        }

        if (_historyBytes == null || !_historyWritable) {
            return false;
        }

        if (!savePacked(_historyBytes as Lang.ByteArray)) {
            return false;
        }

        _historyNeedsRepair = false;

        return true;
    }

    function getHistoryCount() as Number {
        var value = load();
        if (!(value instanceof Lang.ByteArray)) {
            return 0;
        }
        return BloodSugarReading.getPackedCount(value as Lang.ByteArray);
    }

    function getReadingAt(index as Number) {
        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var bytes = value as Lang.ByteArray;
        var count = BloodSugarReading.getPackedCount(bytes);
        if (index < 0 || index >= count) {
            return null;
        }

        var contextId = BloodSugarReading.getPackedContextId(bytes, index);
        var context = "none";
        if (contextId >= 0 && contextId < getContextCount()) {
            context = getContextKey(contextId);
        }
        return BloodSugarReading.create(
            BloodSugarReading.getPackedTime(bytes, index),
            BloodSugarReading.getPackedValueMmol(bytes, index),
            BloodSugarReading.getSourceFromId(
                BloodSugarReading.getPackedSourceId(bytes, index)
            ),
            context
        );
    }

    function getReadingTimeAt(index as Number) as Number? {
        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var bytes = value as Lang.ByteArray;
        var count = BloodSugarReading.getPackedCount(bytes);

        if (index < 0 || index >= count) {
            return null;
        }

        return BloodSugarReading.getPackedTime(bytes, index);
    }

    function getReadingValueMmolAt(index as Number) as Float? {
        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var bytes = value as Lang.ByteArray;
        var count = BloodSugarReading.getPackedCount(bytes);

        if (index < 0 || index >= count) {
            return null;
        }

        return BloodSugarReading.getPackedValueMmol(bytes, index);
    }

    function getRetentionBucketSize(
        timestamp as Number,
        now as Number
    ) as Number {
        if (timestamp < now - MAX_RETENTION_SECONDS) {
            return 0;
        }

        if (timestamp >= now - getRawRetentionSeconds()) {
            return RAW_BUCKET;
        }

        if (timestamp >= now - MIDDLE_RETENTION_SECONDS) {
            return getMiddleBucketSeconds();
        }

        return getOldBucketSeconds();
    }

    function configureHistoryProfileForForeground() as Void {
        var totalMemory = System.getSystemStats().totalMemory;
        var useCompactProfile =
            totalMemory <= COMPACT_PROFILE_MEMORY_LIMIT;
        _compactHistoryProfileCache = useCompactProfile;

        try {
            Properties.setValue(
                PROP_COMPACT_HISTORY_PROFILE,
                useCompactProfile
            );
        } catch (error) {
            System.println("Unable to save history memory profile");
        }
    }

    function usesCompactHistoryProfile() as Boolean {
        if (_compactHistoryProfileCache == null) {
            _compactHistoryProfileCache =
                Properties.getValue(PROP_COMPACT_HISTORY_PROFILE) != false;
        }

        return _compactHistoryProfileCache as Boolean;
    }

    function getMaximumHistoryPoints() as Number {
        if (usesCompactHistoryProfile()) {
            return COMPACT_MAX_POINTS;
        }

        return STANDARD_MAX_POINTS;
    }

    function getRawRetentionSeconds() as Number {
        if (usesCompactHistoryProfile()) {
            return COMPACT_RAW_RETENTION_SECONDS;
        }

        return STANDARD_RAW_RETENTION_SECONDS;
    }

    function getMiddleBucketSeconds() as Number {
        if (usesCompactHistoryProfile()) {
            return COMPACT_MIDDLE_BUCKET_SECONDS;
        }

        return STANDARD_MIDDLE_BUCKET_SECONDS;
    }

    function getOldBucketSeconds() as Number {
        if (usesCompactHistoryProfile()) {
            return COMPACT_OLD_BUCKET_SECONDS;
        }

        return STANDARD_OLD_BUCKET_SECONDS;
    }

    function historyNeedsCompaction(
        bytes as Lang.ByteArray,
        now as Number
    ) as Boolean {
        var count = BloodSugarReading.getPackedCount(bytes);
        if (count > getMaximumHistoryPoints()) {
            return true;
        }

        var activeBucketSize = 0;
        var activeBucket = -1;

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarReading.getPackedTime(bytes, index);
            var bucketSize = getRetentionBucketSize(timestamp, now);

            if (bucketSize == 0) {
                return true;
            }

            if (bucketSize == RAW_BUCKET) {
                activeBucketSize = 0;
                activeBucket = -1;
                continue;
            }

            var bucket = timestamp / bucketSize;
            if (activeBucketSize == bucketSize && activeBucket == bucket) {
                return true;
            }

            activeBucketSize = bucketSize;
            activeBucket = bucket;
        }

        return false;
    }

    function getCompactedHistoryCount(
        bytes as Lang.ByteArray,
        now as Number
    ) as Number {
        var count = BloodSugarReading.getPackedCount(bytes);
        var outputCount = 0;
        var activeBucketSize = 0;
        var activeBucket = -1;

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarReading.getPackedTime(bytes, index);
            var bucketSize = getRetentionBucketSize(timestamp, now);

            if (bucketSize == 0) {
                continue;
            }

            if (bucketSize == RAW_BUCKET) {
                outputCount += 1;
                activeBucketSize = 0;
                activeBucket = -1;
                continue;
            }

            var bucket = timestamp / bucketSize;
            if (activeBucketSize != bucketSize || activeBucket != bucket) {
                outputCount += 1;
                activeBucketSize = bucketSize;
                activeBucket = bucket;
            }
        }

        return outputCount;
    }

    function writeCompactedAverage(
        destination as Lang.ByteArray,
        destinationIndex as Number,
        timestamp as Number,
        totalValue as Float,
        sampleCount as Number,
        sourceId as Number,
        contextId as Number
    ) as Void {
        if (sampleCount > 1) {
            sourceId = BloodSugarReading.SOURCE_ID_AGGREGATE;
            contextId = 0;
        }

        BloodSugarReading.writePackedRecord(
            destination,
            destinationIndex,
            timestamp,
            totalValue / sampleCount,
            sourceId,
            contextId
        );
    }

    function compactPackedHistory(
        bytes as Lang.ByteArray,
        now as Number
    ) as Lang.ByteArray {
        if (!historyNeedsCompaction(bytes, now)) {
            return bytes;
        }

        // Count first so the fixed-size ByteArray is allocated only once.
        var outputCount = getCompactedHistoryCount(bytes, now);
        var skipOutput = 0;
        var maximumPoints = getMaximumHistoryPoints();
        if (outputCount > maximumPoints) {
            skipOutput = outputCount - maximumPoints;
            outputCount = maximumPoints;
        }

        var compacted = BloodSugarReading.createPackedHistory(outputCount);
        var destinationIndex = 0;
        var activeBucketSize = 0;
        var activeBucket = -1;
        var totalValue = 0.0f;
        var sampleCount = 0;
        var lastTimestamp = 0;
        var firstSourceId = 0;
        var firstContextId = 0;
        var count = BloodSugarReading.getPackedCount(bytes);

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarReading.getPackedTime(bytes, index);
            var bucketSize = getRetentionBucketSize(timestamp, now);

            if (bucketSize == 0) {
                continue;
            }

            var bucket = -1;
            if (bucketSize != RAW_BUCKET) {
                bucket = timestamp / bucketSize;
            }

            if (
                sampleCount > 0 &&
                (bucketSize == RAW_BUCKET ||
                    activeBucketSize != bucketSize ||
                    activeBucket != bucket)
            ) {
                if (skipOutput > 0) {
                    skipOutput -= 1;
                } else {
                    writeCompactedAverage(
                        compacted,
                        destinationIndex,
                        lastTimestamp,
                        totalValue,
                        sampleCount,
                        firstSourceId,
                        firstContextId
                    );
                    destinationIndex += 1;
                }

                sampleCount = 0;
                totalValue = 0.0f;
            }

            if (bucketSize == RAW_BUCKET) {
                if (skipOutput > 0) {
                    skipOutput -= 1;
                } else {
                    BloodSugarReading.copyPackedRecord(
                        bytes,
                        index,
                        compacted,
                        destinationIndex
                    );
                    destinationIndex += 1;
                }

                activeBucketSize = 0;
                activeBucket = -1;
                continue;
            }

            if (sampleCount == 0) {
                activeBucketSize = bucketSize;
                activeBucket = bucket;
                firstSourceId = BloodSugarReading.getPackedSourceId(
                    bytes,
                    index
                );
                firstContextId = BloodSugarReading.getPackedContextId(
                    bytes,
                    index
                );
            }

            totalValue += BloodSugarReading.getPackedValueMmol(bytes, index);
            sampleCount += 1;
            lastTimestamp = timestamp;
        }

        if (sampleCount > 0) {
            if (skipOutput > 0) {
                skipOutput -= 1;
            } else {
                writeCompactedAverage(
                    compacted,
                    destinationIndex,
                    lastTimestamp,
                    totalValue,
                    sampleCount,
                    firstSourceId,
                    firstContextId
                );
            }
        }

        return compacted;
    }

    function getHistory() {
        var count = getHistoryCount();

        var history = [] as Array;

        for (var index = 0; index < count; index += 1) {
            var reading = getReadingAt(index);

            if (reading != null) {
                history.add(reading);
            }
        }

        return history;
    }

    function getPartOfHistory(items as Number) {
        var count = getHistoryCount();

        if (count == 0 || items <= 0) {
            return null;
        }

        if (items > count) {
            items = count;
        }

        var history = [] as Array;
        var startIndex = count - items;
        for (var index = startIndex; index < count; index += 1) {
            var reading = getReadingAt(index);

            if (reading != null) {
                history.add(reading);
            }
        }

        return history;
    }

    function getLatestReading() as Array or Dictionary or Null {
        var count = getHistoryCount();
        if (count == 0) {
            return null;
        }
        return getReadingAt(count - 1);
    }

    function addReading(
        valueMmol as Float,
        inputSource as String,
        context as String
    ) as Boolean {
        if (!BloodSugarReading.canPackValue(valueMmol)) {
            return false;
        }

        var value = load();

        if (!(value instanceof Lang.ByteArray) || !_historyWritable) {
            return false;
        }

        var now = Time.now().value();
        var historyBytes = value as Lang.ByteArray;
        if (historyNeedsCompaction(historyBytes, now)) {
            historyBytes = compactPackedHistory(historyBytes, now);
        }

        var candidate = insertPackedReadingSorted(
            historyBytes,

            now,
            valueMmol,

            BloodSugarReading.getSourceId(inputSource),

            getContextIndex(context)
        );

        if (candidate == null) {
            return false;
        }

        if (historyNeedsCompaction(candidate as Lang.ByteArray, now)) {
            candidate = compactPackedHistory(candidate as Lang.ByteArray, now);
        }

        if (!savePacked(candidate as Lang.ByteArray)) {
            return false;
        }

        _historyBytes = candidate;

        return true;
    }

    function save() as Boolean {
        if (_historyBytes == null || !_historyWritable) {
            return false;
        }

        return savePacked(_historyBytes as Lang.ByteArray);
    }

    function savePacked(bytes as Lang.ByteArray) as Boolean {
        try {
            Storage.setValue(STORAGE_KEY, bytes);

            return true;
        } catch (error) {
            System.println("Could not save glucose history: " + error);

            return false;
        }
    }

    function getReadingByTime(bloodSugarValueTime) {
        if (bloodSugarValueTime == null) {
            return null;
        }

        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var index = findPackedIndexByTime(
            value as Lang.ByteArray,

            bloodSugarValueTime.toNumber()
        );

        if (index < 0) {
            return null;
        }

        return getReadingAt(index);
    }

    function updateReadingByTime(
        originalTime,
        valueMmol as Float,
        context as String
    ) as Boolean {
        if (
            originalTime == null ||
            !BloodSugarReading.canPackValue(valueMmol)
        ) {
            return false;
        }

        var historyValue = load();

        if (!(historyValue instanceof Lang.ByteArray) || !_historyWritable) {
            return false;
        }

        var bytes = historyValue as Lang.ByteArray;

        var index = findPackedIndexByTime(
            bytes,

            originalTime.toNumber()
        );

        if (index < 0) {
            return false;
        }

        var timestamp = BloodSugarReading.getPackedTime(bytes, index);
        var oldValue = BloodSugarReading.getPackedValueMmol(bytes, index);
        var sourceId = BloodSugarReading.getPackedSourceId(bytes, index);
        var oldContextId = BloodSugarReading.getPackedContextId(bytes, index);

        if (
            !BloodSugarReading.writePackedRecord(
                bytes,
                index,
                timestamp,
                valueMmol,
                sourceId,
                getContextIndex(context)
            )
        ) {
            return false;
        }

        if (savePacked(bytes)) {
            return true;
        }

        BloodSugarReading.writePackedRecord(
            bytes,
            index,
            timestamp,
            oldValue,
            sourceId,
            oldContextId
        );

        return false;
    }

    function clear() as Boolean {
        var previousHistory = _historyBytes;
        var previousWritable = _historyWritable;
        var empty = BloodSugarReading.createPackedHistory(0);
        _historyWritable = true;

        if (savePacked(empty)) {
            _historyBytes = empty;
            _historyNeedsRepair = false;
            return true;
        }

        _historyBytes = previousHistory;
        _historyWritable = previousWritable;
        return false;
    }

    function findPackedIndexByTime(
        bytes as Lang.ByteArray,
        timestamp as Number
    ) as Number {
        var count = BloodSugarReading.getPackedCount(bytes);

        for (var index = 0; index < count; index += 1) {
            var storedTime = BloodSugarReading.getPackedTime(bytes, index);

            if (storedTime == timestamp) {
                return index;
            }

            if (storedTime > timestamp) {
                break;
            }
        }

        return -1;
    }

    function packedContainsTime(
        bytes as Lang.ByteArray,
        timestamp as Number
    ) as Boolean {
        return findPackedIndexByTime(bytes, timestamp) >= 0;
    }

    function insertPackedReadingSorted(
        bytes as Lang.ByteArray,
        timestamp as Number,
        valueMmol as Float,
        sourceId as Number,
        contextId as Number
    ) as Lang.ByteArray? {
        if (timestamp <= 0 || !BloodSugarReading.canPackValue(valueMmol)) {
            return null;
        }

        var currentCount = BloodSugarReading.getPackedCount(bytes);
        var insertionIndex = currentCount;
        for (var index = 0; index < currentCount; index += 1) {
            var storedTime = BloodSugarReading.getPackedTime(bytes, index);

            if (storedTime == timestamp) {
                return null;
            }

            if (storedTime > timestamp) {
                insertionIndex = index;
                break;
            }
        }

        var maximumPoints = getMaximumHistoryPoints();
        if (currentCount >= maximumPoints && insertionIndex == 0) {
            return null;
        }

        var candidateCount = currentCount + 1;
        if (candidateCount > maximumPoints) {
            candidateCount = maximumPoints;
        }
        var candidate = BloodSugarReading.createPackedHistory(candidateCount);
        var firstSourceIndex = 0;
        var destinationInsertionIndex = insertionIndex;
        if (currentCount >= maximumPoints) {
            firstSourceIndex = 1;

            destinationInsertionIndex -= 1;
        }

        var destinationIndex = 0;
        for (
            var sourceIndex = firstSourceIndex;
            sourceIndex < insertionIndex;
            sourceIndex += 1
        ) {
            BloodSugarReading.copyPackedRecord(
                bytes,
                sourceIndex,
                candidate,
                destinationIndex
            );

            destinationIndex += 1;
        }

        if (destinationIndex != destinationInsertionIndex) {
            return null;
        }

        if (
            !BloodSugarReading.writePackedRecord(
                candidate,
                destinationIndex,
                timestamp,
                valueMmol,
                sourceId,
                contextId
            )
        ) {
            return null;
        }

        destinationIndex += 1;

        for (
            var sourceIndexAfter = insertionIndex;
            sourceIndexAfter < currentCount &&
            destinationIndex < candidateCount;
            sourceIndexAfter += 1
        ) {
            BloodSugarReading.copyPackedRecord(
                bytes,
                sourceIndexAfter,
                candidate,
                destinationIndex
            );

            destinationIndex += 1;
        }

        return candidate;
    }

    function MollToMgdl(mmol as Float) as Float {
        return mmol * 18.018f;
    }

    function MgdlToMoll(mgdl as Float) as Float {
        return mgdl / 18.018f;
    }

    function formatValue(valueMmol as Float, useMgdl as Boolean) as String {
        if (useMgdl) {
            return MollToMgdl(valueMmol).format("%.0f");
        }

        return valueMmol.format("%.1f");
    }

    function getUnitText(useMgdl as Boolean) as String {
        if (useMgdl) {
            return "mg/dL";
        }

        return "mmol/L";
    }

    function getBloodMonitorText(BloodMonitor as Number) as String {
        switch (BloodMonitor) {
            case MONITOR_NONE:
                return "no monitor";

            case MONITOR_ABBOTT:
                return "Abbott FreeStyle";

            case MONITOR_BLE:
                return "Bluetooth LE";
        }

        return "unknown";
    }

    function getUseMgdl() as Boolean {
        if (_useMgdlCache == null) {
            _useMgdlCache = Properties.getValue(PROP_USE_MGDL) == true;
        }

        return _useMgdlCache as Boolean;
    }

    function setUseMgdl(useMgdl as Boolean) as Void {
        Properties.setValue(PROP_USE_MGDL, useMgdl);

        _useMgdlCache = useMgdl;
    }

    function getCachedRangeValue(propertyKey as String) {
        if (propertyKey.equals(PROP_DANGER_LOW)) {
            return _dangerLowMmolCache;
        }

        if (propertyKey.equals(PROP_LOW)) {
            return _lowMmolCache;
        }

        if (propertyKey.equals(PROP_HIGH)) {
            return _highMmolCache;
        }

        if (propertyKey.equals(PROP_DANGER_HIGH)) {
            return _dangerHighMmolCache;
        }

        if (propertyKey.equals(PROP_NOTIFICATION_LOW)) {
            return _notificationLowMmolCache;
        }

        if (propertyKey.equals(PROP_NOTIFICATION_HIGH)) {
            return _notificationHighMmolCache;
        }

        return null;
    }

    function setCachedRangeValue(
        propertyKey as String,
        valueMmol as Float
    ) as Void {
        if (propertyKey.equals(PROP_DANGER_LOW)) {
            _dangerLowMmolCache = valueMmol;
            return;
        }

        if (propertyKey.equals(PROP_LOW)) {
            _lowMmolCache = valueMmol;
            return;
        }

        if (propertyKey.equals(PROP_HIGH)) {
            _highMmolCache = valueMmol;
            return;
        }

        if (propertyKey.equals(PROP_DANGER_HIGH)) {
            _dangerHighMmolCache = valueMmol;
            return;
        }

        if (propertyKey.equals(PROP_NOTIFICATION_LOW)) {
            _notificationLowMmolCache = valueMmol;
            return;
        }

        if (propertyKey.equals(PROP_NOTIFICATION_HIGH)) {
            _notificationHighMmolCache = valueMmol;
        }
    }

    function getRangePropertyMmol(
        propertyKey as String,
        defaultMgdl as Float
    ) as Float {
        var cached = getCachedRangeValue(propertyKey);

        if (cached != null) {
            return cached as Float;
        }

        var value = Properties.getValue(propertyKey);

        var result = MgdlToMoll(defaultMgdl);

        if (value != null) {
            result = MgdlToMoll(value.toFloat());
        }

        setCachedRangeValue(propertyKey, result);

        return result;
    }

    function setRangePropertyMmol(
        propertyKey as String,
        valueMmol as Float
    ) as Void {
        Properties.setValue(propertyKey, MollToMgdl(valueMmol));

        setCachedRangeValue(propertyKey, valueMmol);
    }

    function getDangerLowMmol() as Float {
        return getRangePropertyMmol(PROP_DANGER_LOW, 80.0f);
    }

    function setDangerLowMmol(value as Float) as Void {
        setRangePropertyMmol(PROP_DANGER_LOW, value);
    }

    function getLowMmol() as Float {
        return getRangePropertyMmol(PROP_LOW, 90.0f);
    }

    function setLowMmol(value as Float) as Void {
        setRangePropertyMmol(PROP_LOW, value);
    }

    function getHighMmol() as Float {
        return getRangePropertyMmol(PROP_HIGH, 140.0f);
    }

    function setHighMmol(value as Float) as Void {
        setRangePropertyMmol(PROP_HIGH, value);
    }

    function getDangerHighMmol() as Float {
        return getRangePropertyMmol(PROP_DANGER_HIGH, 220.0f);
    }

    function setDangerHighMmol(value as Float) as Void {
        setRangePropertyMmol(PROP_DANGER_HIGH, value);
    }

    function getBloodSugarZones() as Array<Float> {
        var zones = [0.0f, 0.0f, 0.0f, 0.0f];
        fillBloodSugarZones(zones);
        return zones;
    }

    function fillBloodSugarZones(zones as Array<Float>) as Void {
        if (zones.size() < 4) {
            return;
        }

        var dangerLow = getDangerLowMmol();
        var low = getLowMmol();
        var high = getHighMmol();
        var dangerHigh = getDangerHighMmol();
        var minimumGap = MgdlToMoll(1.0f);

        if (dangerLow < minimumGap) {
            dangerLow = minimumGap;
        }

        if (low <= dangerLow) {
            low = dangerLow + minimumGap;
        }

        if (high <= low) {
            high = low + minimumGap;
        }

        if (dangerHigh <= high) {
            dangerHigh = high + minimumGap;
        }

        zones[0] = dangerLow;
        zones[1] = low;
        zones[2] = high;
        zones[3] = dangerHigh;
    }

    function getTargetLowMmol() as Float {
        return getLowMmol();
    }

    function setTargetLowMmol(value as Float) as Void {
        setLowMmol(value);
    }

    function getTargetHighMmol() as Float {
        return getHighMmol();
    }

    function setTargetHighMmol(value as Float) as Void {
        setHighMmol(value);
    }

    function getSetupDone() as Boolean {
        var value = Storage.getValue(STORAGE_SETUP_DONE);

        if (value instanceof Boolean) {
            return value as Boolean;
        }

        return false;
    }

    function setSetupDone(done as Boolean) as Void {
        try {
            Storage.setValue(STORAGE_SETUP_DONE, done);

            System.println("Setup done saved: " + done);
        } catch (error) {
            System.println("Could not save setup state");
        }
    }

    function getConfirmBeforeSave() as Boolean {
        if (_confirmBeforeSaveCache == null) {
            _confirmBeforeSaveCache =
                Properties.getValue(PROP_CONFIRM_SAVE) != false;
        }

        return _confirmBeforeSaveCache as Boolean;
    }

    function setConfirmBeforeSave(confirm as Boolean) as Void {
        Properties.setValue(PROP_CONFIRM_SAVE, confirm);
        _confirmBeforeSaveCache = confirm;
    }

    function getDefaultContextIndex() as Number {
        if (_defaultContextIndexCache != null) {
            return _defaultContextIndexCache as Number;
        }

        var value = Properties.getValue(PROP_DEFAULT_CONTEXT);

        var index = 0;

        if (value != null) {
            index = value.toNumber();

            if (index < 0 || index >= getContextCount()) {
                index = 0;
            }
        }

        _defaultContextIndexCache = index;

        return index;
    }

    function setDefaultContextIndex(index as Number) as Void {
        var normalizedIndex = normalizeContextIndex(index);

        Properties.setValue(PROP_DEFAULT_CONTEXT, normalizedIndex);

        _defaultContextIndexCache = normalizedIndex;
    }

    function getContextCount() as Number {
        return 7;
    }

    function normalizeContextIndex(index as Number) as Number {
        var count = getContextCount();

        while (index < 0) {
            index += count;
        }

        while (index >= count) {
            index -= count;
        }

        return index;
    }

    function getContextKey(index as Number) as String {
        index = normalizeContextIndex(index);

        if (index == 1) {
            return "fasting";
        }

        if (index == 2) {
            return "before_meal";
        }

        if (index == 3) {
            return "after_meal";
        }

        if (index == 4) {
            return "bedtime";
        }

        if (index == 5) {
            return "before_exercise";
        }

        if (index == 6) {
            return "after_exercise";
        }

        return "none";
    }

    function getContextLabel(index as Number) as String {
        index = normalizeContextIndex(index);

        if (index == 1) {
            return "Fasting";
        }

        if (index == 2) {
            return "Before meal";
        }

        if (index == 3) {
            return "After meal";
        }

        if (index == 4) {
            return "Bedtime";
        }

        if (index == 5) {
            return "Before exercise";
        }

        if (index == 6) {
            return "After exercise";
        }

        return "No context";
    }

    function getContextIndex(context as String) as Number {
        if (context.equals("fasting")) {
            return 1;
        }

        if (context.equals("before_meal")) {
            return 2;
        }

        if (context.equals("after_meal")) {
            return 3;
        }

        if (context.equals("bedtime")) {
            return 4;
        }

        if (context.equals("before_exercise")) {
            return 5;
        }

        if (context.equals("after_exercise")) {
            return 6;
        }

        return 0;
    }

    function normalizeContext(context as String) as String {
        return getContextKey(getContextIndex(context));
    }

    function getAppVersion() as String {
        var value = Properties.getValue(PROP_APP_VERSION);

        return value.toString();
    }

    function split(fullString as String, splitter as String) as [String] {
        var parts = [];
        var startIndex = 0;
        var stringLength = fullString.length();
        var splitterLength = splitter.length();

        if (splitterLength == 0) {
            parts.add(fullString);
            return parts;
        }

        while (startIndex <= stringLength) {
            var endIndex = startIndex;

            while (endIndex < stringLength) {
                var nextEnd = endIndex + splitterLength;

                if (nextEnd > stringLength) {
                    break;
                }

                if (fullString.substring(endIndex, nextEnd).equals(splitter)) {
                    break;
                }

                endIndex += 1;
            }

            parts.add(fullString.substring(startIndex, endIndex));

            if (endIndex >= stringLength) {
                break;
            }

            startIndex = endIndex + splitterLength;
        }

        return parts;
    }

    function isSupportedVersion(
        appVersion as String,
        minVersion as String
    ) as Boolean {
        var versionParts = split(appVersion, ".") as [String];
        var minVersionParts = split(minVersion, ".") as [String];
        var maxLen = versionParts.size();

        if (minVersionParts.size() > maxLen) {
            maxLen = minVersionParts.size();
        }

        for (var index = 0; index < maxLen; index += 1) {
            var versionNum = 0 as Number;
            var minVersionNum = 0 as Number;

            if (
                index < versionParts.size() &&
                versionParts[index].length() > 0
            ) {
                versionNum = versionParts[index].toNumber();
            }

            if (
                index < minVersionParts.size() &&
                minVersionParts[index].length() > 0
            ) {
                minVersionNum = minVersionParts[index].toNumber();
            }

            if (versionNum > minVersionNum) {
                return true;
            }

            if (versionNum < minVersionNum) {
                return false;
            }
        }

        return true;
    }

    function isBleSupported() as Boolean {
        if (_bleSupportedCache == null) {
            _bleSupportedCache = isSupportedVersion(getAppVersion(), "1.0.0");
        }

        return _bleSupportedCache as Boolean;
    }

    function addReadingsBatch(readings) as Number {
        if (!(readings instanceof Array)) {
            return -1;
        }

        var historyValue = load();

        if (!(historyValue instanceof Lang.ByteArray) || !_historyWritable) {
            return -1;
        }

        var now = Time.now().value();
        var candidate = historyValue as Lang.ByteArray;
        var compactedBeforeInsert = false;
        if (historyNeedsCompaction(candidate, now)) {
            candidate = compactPackedHistory(candidate, now);
            compactedBeforeInsert = true;
        }

        var addedCount = 0;

        for (var index = 0; index < readings.size(); index += 1) {
            var incoming = readings[index];

            if (!(incoming instanceof Array) || incoming.size() < 4) {
                continue;
            }

            if (
                incoming[0] == null ||
                incoming[1] == null ||
                incoming[2] == null ||
                incoming[3] == null
            ) {
                continue;
            }

            var timestamp = incoming[0].toNumber();
            var valueMmol = incoming[1].toFloat();
            var source = incoming[2].toString();
            var context = incoming[3].toString();

            if (timestamp <= 0 || !BloodSugarReading.canPackValue(valueMmol)) {
                continue;
            }

            if (timestamp < now - MAX_RETENTION_SECONDS) {
                continue;
            }

            if (
                BloodSugarReading.getPackedCount(candidate) >=
                    getMaximumHistoryPoints() &&
                historyNeedsCompaction(candidate, now)
            ) {
                candidate = compactPackedHistory(candidate, now);
            }

            var nextCandidate = insertPackedReadingSorted(
                candidate,
                timestamp,
                valueMmol,
                BloodSugarReading.getSourceId(source),
                getContextIndex(context)
            );

            if (nextCandidate == null) {
                continue;
            }

            candidate = nextCandidate as Lang.ByteArray;
            addedCount += 1;
        }

        if (addedCount == 0) {
            if (compactedBeforeInsert) {
                if (!savePacked(candidate)) {
                    return -1;
                }
                _historyBytes = candidate;
            }
            return 0;
        }

        if (historyNeedsCompaction(candidate, now)) {
            candidate = compactPackedHistory(candidate, now);
        }

        if (!savePacked(candidate)) {
            return -1;
        }

        _historyBytes = candidate;

        return addedCount;
    }

    function hasReadingByTime(timestamp as Number) as Boolean {
        var value = load();
        if (!(value instanceof Lang.ByteArray)) {
            return false;
        }

        return packedContainsTime(value as Lang.ByteArray, timestamp);
    }

    function getCustomContextNames() as Array<String> {
        var names = [] as Array<String>;
        var value = Properties.getValue(PROP_CUSTOM_CONTEXTS);

        if (!(value instanceof Array)) {
            return names;
        }

        var contexts = value as Array;

        for (var index = 0; index < contexts.size(); index += 1) {
            var context = contexts[index];

            if (!(context instanceof Dictionary)) {
                continue;
            }

            var name = (context as Dictionary)["name"];

            if (name instanceof String && (name as String).length() > 0) {
                names.add(name as String);
            }
        }

        return names;
    }

    public function getBloodMonitors() as Array<String> {
        var monitors = ["Abbott FreeStyle"] as Array<String>;

        if (isBleSupported()) {
            monitors.add("Bluetooth LE");
        }

        return monitors;
    }

    public function getBloodMonitorIdAt(index as Number) as Number {
        if (index == 0) {
            return MONITOR_ABBOTT;
        }

        if (index == 1 && isBleSupported()) {
            return MONITOR_BLE;
        }

        return MONITOR_NONE;
    }

    public function setBloodMonitor(selected as Number) as Void {
        Properties.setValue(PROP_BLOOD_MONITOR_INDEX, selected);

        _bloodMonitorCache = selected;
    }

    public function getBloodMonitor() as Number {
        if (_bloodMonitorCache != null) {
            return _bloodMonitorCache as Number;
        }

        var value = Properties.getValue(PROP_BLOOD_MONITOR_INDEX);
        var selected = BloodSugarMonitor.NONE;

        if (value instanceof Number) {
            selected = value as Number;
        }

        _bloodMonitorCache = selected;

        return selected;
    }

    public function getUsername() as String {
        var value = Storage.getValue(PROP_USERNAME);

        if (value instanceof String) {
            return value as String;
        }

        return "";
    }

    function getPassword() as String {
        var value = Storage.getValue(PROP_PASSWORD);

        if (value instanceof String) {
            return value as String;
        }

        return "";
    }

    function saveUsernamePassword(
        username as String,
        password as String
    ) as Boolean {
        try {
            Storage.setValue(PROP_USERNAME, username);

            Storage.setValue(PROP_PASSWORD, password);

            return true;
        } catch (error) {
            System.println(
                "Could not save LibreLinkUp credentials: " + error.toString()
            );

            return false;
        }
    }

    function clearUsernamePassword() as Void {
        try {
            Storage.deleteValue(PROP_USERNAME);

            Storage.deleteValue(PROP_PASSWORD);
        } catch (error) {
            System.println(
                "Could not clear LibreLinkUp credentials: " + error.toString()
            );
        }
    }

    function getNotificationsEnabled() as Boolean {
        if (_notificationsEnabledCache == null) {
            _notificationsEnabledCache =
                Properties.getValue(PROP_NOTIFICATIONS_ENABLED) != false;
        }

        return _notificationsEnabledCache as Boolean;
    }

    function setNotificationsEnabled(enabled as Boolean) as Void {
        Properties.setValue(PROP_NOTIFICATIONS_ENABLED, enabled);
        _notificationsEnabledCache = enabled;
    }

    function getNotificationLowMmol() as Float {
        return getRangePropertyMmol(PROP_NOTIFICATION_LOW, 70.0f);
    }

    function setNotificationLowMmol(valueMmol as Float) as Void {
        setRangePropertyMmol(PROP_NOTIFICATION_LOW, valueMmol);
    }

    function getNotificationHighMmol() as Float {
        return getRangePropertyMmol(PROP_NOTIFICATION_HIGH, 180.0f);
    }

    function setNotificationHighMmol(valueMmol as Float) as Void {
        setRangePropertyMmol(PROP_NOTIFICATION_HIGH, valueMmol);
    }

    function getNotificationType(valueMmol as Float) as Number {
        if (!getNotificationsEnabled()) {
            return NOTIFICATION_NONE;
        }

        if (valueMmol <= getNotificationLowMmol()) {
            return NOTIFICATION_LOW;
        }

        if (valueMmol >= getNotificationHighMmol()) {
            return NOTIFICATION_HIGH;
        }

        return NOTIFICATION_NONE;
    }

    function deleteReadingByTime(originalTime) as Boolean {
        if (originalTime == null) {
            return false;
        }

        var historyValue = load();
        if (!(historyValue instanceof Lang.ByteArray) || !_historyWritable) {
            return false;
        }

        var bytes = historyValue as Lang.ByteArray;
        var readingIndex = findPackedIndexByTime(
            bytes,
            originalTime.toNumber()
        );

        if (readingIndex < 0) {
            return false;
        }

        var count = BloodSugarReading.getPackedCount(bytes);
        var candidate = BloodSugarReading.createPackedHistory(count - 1);
        var destinationIndex = 0;

        for (var sourceIndex = 0; sourceIndex < count; sourceIndex += 1) {
            if (sourceIndex == readingIndex) {
                continue;
            }

            BloodSugarReading.copyPackedRecord(
                bytes,
                sourceIndex,
                candidate,
                destinationIndex
            );

            destinationIndex += 1;
        }

        if (!savePacked(candidate)) {
            return false;
        }

        _historyBytes = candidate;
        return true;
    }
}
