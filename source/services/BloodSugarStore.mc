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
import Toybox.Time;

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

    const COMPACT_PROFILE_MEMORY_LIMIT = 128 * 1024;
    const PROP_APP_VERSION = "appVersion";
    const PROP_COMPACT_HISTORY_PROFILE = "compactHistoryProfile";
    const STORAGE_SETUP_DONE = "setupDone";
    const PROP_USE_MGDL = "useMgdl";

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
    var _useMgdlCache as Boolean? = null;
    var _confirmBeforeSaveCache as Boolean? = null;
    var _defaultContextIndexCache as Number? = null;
    var _bloodMonitorCache as Number? = null;
    var _notificationsEnabledCache as Boolean? = null;

    var _dangerLowMmolCache as Float? = null;
    var _lowMmolCache as Float? = null;
    var _highMmolCache as Float? = null;
    var _dangerHighMmolCache as Float? = null;
    var _notificationLowMmolCache as Float? = null;
    var _notificationHighMmolCache as Float? = null;

    var _bleSupportedCache as Boolean? = null;
    var _compactHistoryProfileCache as Boolean? = null;

    const NOTIFICATION_NONE = 0;
    const NOTIFICATION_LOW = 1;
    const NOTIFICATION_HIGH = 2;

    const MONITOR_NONE = 0;
    const MONITOR_ABBOTT = 1;
    const MONITOR_DEXCOM = 2;
    const MONITOR_XDRIP = 3;
    const MONITOR_BLE = 4;

    var _historyBytes as Lang.ByteArray? = null;
    var _historyNeedsRepair as Boolean = false;
    var _historyWritable as Boolean = true;

    (:typecheck(false))
    function readStorageValue(key as String) as Object? {
        return BloodSugarSharedStorage.readValue(key);
    }

    (:typecheck(false))
    function writeStorageValue(key as String, value as Object?) as Void {
        BloodSugarSharedStorage.writeValue(key, value);
    }

    (:typecheck(false))
    function readPropertyValue(key as String) as Object? {
        return BloodSugarSharedStorage.readProperty(key);
    }

    (:typecheck(false))
    function writePropertyValue(key as String, value as Object?) as Void {
        BloodSugarSharedStorage.writeProperty(key, value);
    }

    function load() as Lang.ByteArray {
        if (_historyBytes != null) {
            return _historyBytes;
        }
        var saved;

        try {
            saved = BloodSugarHistoryStorage.readRaw();
        } catch (error) {
            _historyBytes = BloodSugarPackedReading.createHistory(0);
            _historyWritable = false;
            _historyNeedsRepair = false;
            return _historyBytes;
        }
        if (saved == null) {
            _historyBytes = BloodSugarPackedReading.createHistory(0);
            _historyWritable = true;
            _historyNeedsRepair = false;
            return _historyBytes;
        }
        if (saved instanceof Lang.ByteArray) {
            var bytes = saved as Lang.ByteArray;
            if (!BloodSugarPackedReading.isHistory(bytes)) {
                System.println("Unsupported packed glucose history");
                _historyBytes = BloodSugarPackedReading.createHistory(0);
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
            var migrated = migrateLegacyHistory(saved as Array<Object?>);
            _historyBytes = migrated;

            _historyWritable = true;

            if (savePacked(migrated)) {
                _historyNeedsRepair = false;
            } else {
                _historyNeedsRepair = true;
            }

            return _historyBytes;
        }

        _historyBytes = BloodSugarPackedReading.createHistory(0);
        _historyWritable = false;
        _historyNeedsRepair = false;
        return _historyBytes;
    }

    function invalidateHistoryCache() as Void {
        _historyBytes = null;
        BloodSugarHistoryStorage.invalidate();
    }

    function migrateLegacyHistory(
        legacyHistory as Array<Object?>
    ) as Lang.ByteArray {
        var validCount = 0;

        for (var index = 0; index < legacyHistory.size(); index += 1) {
            var normalized = BloodSugarReading.normalize(
                legacyHistory[index],
                index
            );

            if (
                normalized != null &&
                normalized[BloodSugarReading.TIME].toNumber() > 0 &&
                BloodSugarPackedReading.canPackValue(
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
        var packed = BloodSugarPackedReading.createHistory(keepCount);
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
                !BloodSugarPackedReading.canPackValue(
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
                BloodSugarPackedReading.write(
                    packed,
                    writeIndex,
                    reading[BloodSugarReading.TIME].toNumber(),
                    reading[BloodSugarReading.VALUE_MMOL].toFloat(),
                    BloodSugarPackedReading.getSourceId(source),
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
        return BloodSugarPackedReading.getCount(value as Lang.ByteArray);
    }

    function getReadingAt(index as Number) as BloodSugarReading.Record? {
        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var bytes = value as Lang.ByteArray;
        var count = BloodSugarPackedReading.getCount(bytes);
        if (index < 0 || index >= count) {
            return null;
        }

        var contextId = BloodSugarPackedReading.getContextIdAt(bytes, index);
        var context = "none";
        if (contextId >= 0 && contextId < getContextCount()) {
            context = getContextKey(contextId);
        }
        return BloodSugarReading.create(
            BloodSugarPackedReading.getTime(bytes, index),
            BloodSugarPackedReading.getValueMmol(bytes, index),
            BloodSugarPackedReading.getSource(
                BloodSugarPackedReading.getSourceIdAt(bytes, index)
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
        var count = BloodSugarPackedReading.getCount(bytes);

        if (index < 0 || index >= count) {
            return null;
        }

        return BloodSugarPackedReading.getTime(bytes, index);
    }

    function getReadingValueMmolAt(index as Number) as Float? {
        var value = load();

        if (!(value instanceof Lang.ByteArray)) {
            return null;
        }

        var bytes = value as Lang.ByteArray;
        var count = BloodSugarPackedReading.getCount(bytes);

        if (index < 0 || index >= count) {
            return null;
        }

        return BloodSugarPackedReading.getValueMmol(bytes, index);
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
        var useCompactProfile = totalMemory <= COMPACT_PROFILE_MEMORY_LIMIT;
        _compactHistoryProfileCache = useCompactProfile;

        try {
            writePropertyValue(PROP_COMPACT_HISTORY_PROFILE, useCompactProfile);
        } catch (error) {
            System.println("Unable to save history memory profile");
        }
    }

    function usesCompactHistoryProfile() as Boolean {
        if (_compactHistoryProfileCache == null) {
            var value = readPropertyValue(PROP_COMPACT_HISTORY_PROFILE);
            _compactHistoryProfileCache = value != false;
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
        var count = BloodSugarPackedReading.getCount(bytes);
        if (count > getMaximumHistoryPoints()) {
            return true;
        }

        var activeBucketSize = 0;
        var activeBucket = -1;

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarPackedReading.getTime(bytes, index);
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
        var count = BloodSugarPackedReading.getCount(bytes);
        var outputCount = 0;
        var activeBucketSize = 0;
        var activeBucket = -1;

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarPackedReading.getTime(bytes, index);
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
            sourceId = BloodSugarPackedReading.SOURCE_ID_AGGREGATE;
            contextId = 0;
        }

        BloodSugarPackedReading.write(
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

        var compacted = BloodSugarPackedReading.createHistory(outputCount);
        var destinationIndex = 0;
        var activeBucketSize = 0;
        var activeBucket = -1;
        var totalValue = 0.0f;
        var sampleCount = 0;
        var lastTimestamp = 0;
        var firstSourceId = 0;
        var firstContextId = 0;
        var count = BloodSugarPackedReading.getCount(bytes);

        for (var index = 0; index < count; index += 1) {
            var timestamp = BloodSugarPackedReading.getTime(bytes, index);
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
                    BloodSugarPackedReading.copy(
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
                firstSourceId = BloodSugarPackedReading.getSourceIdAt(
                    bytes,
                    index
                );
                firstContextId = BloodSugarPackedReading.getContextIdAt(
                    bytes,
                    index
                );
            }

            totalValue += BloodSugarPackedReading.getValueMmol(bytes, index);
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

    function getHistory() as Array<BloodSugarReading.Record> {
        var count = getHistoryCount();

        var history = [] as Array<BloodSugarReading.Record>;

        for (var index = 0; index < count; index += 1) {
            var reading = getReadingAt(index);

            if (reading != null) {
                history.add(reading);
            }
        }

        return history;
    }

    function getPartOfHistory(
        items as Number
    ) as Array<BloodSugarReading.Record>? {
        var count = getHistoryCount();

        if (count == 0 || items <= 0) {
            return null;
        }

        if (items > count) {
            items = count;
        }

        var history = [] as Array<BloodSugarReading.Record>;
        var startIndex = count - items;
        for (var index = startIndex; index < count; index += 1) {
            var reading = getReadingAt(index);

            if (reading != null) {
                history.add(reading);
            }
        }

        return history;
    }

    function getLatestReading() as BloodSugarReading.Record? {
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
        if (!BloodSugarPackedReading.canPackValue(valueMmol)) {
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

            BloodSugarPackedReading.getSourceId(inputSource),

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
        if (BloodSugarHistoryStorage.savePacked(bytes)) {
            return true;
        }
        System.println("Could not save glucose history");
        return false;
    }

    function getReadingByTime(
        bloodSugarValueTime as Number?
    ) as BloodSugarReading.Record? {
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
        originalTime as Number?,
        valueMmol as Float,
        context as String
    ) as Boolean {
        if (
            originalTime == null ||
            !BloodSugarPackedReading.canPackValue(valueMmol)
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

        var timestamp = BloodSugarPackedReading.getTime(bytes, index);
        var oldValue = BloodSugarPackedReading.getValueMmol(bytes, index);
        var sourceId = BloodSugarPackedReading.getSourceIdAt(bytes, index);
        var oldContextId = BloodSugarPackedReading.getContextIdAt(bytes, index);

        if (
            !BloodSugarPackedReading.write(
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

        BloodSugarPackedReading.write(
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
        var empty = BloodSugarPackedReading.createHistory(0);
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
        var count = BloodSugarPackedReading.getCount(bytes);

        for (var index = 0; index < count; index += 1) {
            var storedTime = BloodSugarPackedReading.getTime(bytes, index);

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
        if (
            timestamp <= 0 ||
            !BloodSugarPackedReading.canPackValue(valueMmol)
        ) {
            return null;
        }

        var currentCount = BloodSugarPackedReading.getCount(bytes);
        var insertionIndex = currentCount;
        for (var index = 0; index < currentCount; index += 1) {
            var storedTime = BloodSugarPackedReading.getTime(bytes, index);

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
        var candidate = BloodSugarPackedReading.createHistory(candidateCount);
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
            BloodSugarPackedReading.copy(
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
            !BloodSugarPackedReading.write(
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
            BloodSugarPackedReading.copy(
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
            case MONITOR_DEXCOM:
                return "Dexcom";
            case MONITOR_XDRIP:
                return "Xdrip+";
            case MONITOR_BLE:
                return "Bluetooth LE";
        }

        return "unknown";
    }

    function getUseMgdl() as Boolean {
        if (_useMgdlCache == null) {
            var value = readPropertyValue(PROP_USE_MGDL);
            _useMgdlCache = value == true;
        }

        return _useMgdlCache as Boolean;
    }

    function setUseMgdl(useMgdl as Boolean) as Void {
        writePropertyValue(PROP_USE_MGDL, useMgdl);

        _useMgdlCache = useMgdl;
    }

    function getCachedRangeValue(propertyKey as String) as Float? {
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

        var value = readPropertyValue(propertyKey);

        var result = MgdlToMoll(defaultMgdl);

        if (value instanceof Float) {
            result = MgdlToMoll(value as Float);
        } else if (value instanceof Number) {
            result = MgdlToMoll((value as Number).toFloat());
        }

        setCachedRangeValue(propertyKey, result);

        return result;
    }

    function setRangePropertyMmol(
        propertyKey as String,
        valueMmol as Float
    ) as Void {
        writePropertyValue(propertyKey, MollToMgdl(valueMmol));

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
        var value = readStorageValue(STORAGE_SETUP_DONE);

        if (value instanceof Boolean) {
            return value as Boolean;
        }

        return false;
    }

    function setSetupDone(done as Boolean) as Void {
        try {
            writeStorageValue(STORAGE_SETUP_DONE, done);

            System.println("Setup done saved: " + done);
        } catch (error) {
            System.println("Could not save setup state");
        }
    }

    function getConfirmBeforeSave() as Boolean {
        if (_confirmBeforeSaveCache == null) {
            var value = readPropertyValue(PROP_CONFIRM_SAVE);
            _confirmBeforeSaveCache = value != false;
        }

        return _confirmBeforeSaveCache as Boolean;
    }

    function setConfirmBeforeSave(confirm as Boolean) as Void {
        writePropertyValue(PROP_CONFIRM_SAVE, confirm);
        _confirmBeforeSaveCache = confirm;
    }

    function getDefaultContextIndex() as Number {
        if (_defaultContextIndexCache != null) {
            return _defaultContextIndexCache as Number;
        }

        var value = readPropertyValue(PROP_DEFAULT_CONTEXT);

        var index = 0;

        if (value instanceof Number) {
            index = value as Number;
        } else if (value instanceof Float) {
            index = (value as Float).toNumber();
        }

        if (index < 0 || index >= getContextCount()) {
            index = 0;
        }

        _defaultContextIndexCache = index;

        return index;
    }

    function setDefaultContextIndex(index as Number) as Void {
        var normalizedIndex = normalizeContextIndex(index);

        writePropertyValue(PROP_DEFAULT_CONTEXT, normalizedIndex);

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
        var value = readPropertyValue(PROP_APP_VERSION);

        if (value == null) {
            return "";
        }

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

    function hasReadingByTime(timestamp as Number) as Boolean {
        var value = load();
        if (!(value instanceof Lang.ByteArray)) {
            return false;
        }

        return packedContainsTime(value as Lang.ByteArray, timestamp);
    }

    function getCustomContextNames() as Array<String> {
        var names = [] as Array<String>;
        var value = readPropertyValue(PROP_CUSTOM_CONTEXTS);

        if (!(value instanceof Array)) {
            return names;
        }

        var contexts = value as Array<Object?>;

        for (var index = 0; index < contexts.size(); index += 1) {
            var context = contexts[index];

            if (!(context instanceof Dictionary)) {
                continue;
            }

            var dictionary = context as Dictionary<Object, Object?>;
            var name = dictionary["name"];

            if (name instanceof String && (name as String).length() > 0) {
                names.add(name as String);
            }
        }

        return names;
    }

    public function getBloodMonitors() as Array<String> {
        var monitors =
            ["Abbott FreeStyle", "Dexcom", "XDrip+"] as Array<String>;

        if (isBleSupported()) {
            monitors.add("Bluetooth LE");
        }

        return monitors;
    }

    public function getBloodMonitorIdAt(index as Number) as Number {
        if (index == 0) {
            return MONITOR_ABBOTT;
        }
        if (index == 1) {
            return MONITOR_DEXCOM;
        }
        if (index == 2) {
            return MONITOR_XDRIP;
        }

        if (index == 3 && isBleSupported()) {
            return MONITOR_BLE;
        }

        return MONITOR_NONE;
    }

    public function setBloodMonitor(selected as Number) as Void {
        writePropertyValue(PROP_BLOOD_MONITOR_INDEX, selected);

        _bloodMonitorCache = selected;
    }

    public function getBloodMonitor() as Number {
        if (_bloodMonitorCache != null) {
            return _bloodMonitorCache as Number;
        }

        var value = readPropertyValue(PROP_BLOOD_MONITOR_INDEX);
        var selected = BloodSugarMonitor.NONE;

        if (value instanceof Number) {
            selected = value as Number;
        }

        _bloodMonitorCache = selected;

        return selected;
    }

    function getNotificationsEnabled() as Boolean {
        if (_notificationsEnabledCache == null) {
            var value = readPropertyValue(PROP_NOTIFICATIONS_ENABLED);
            _notificationsEnabledCache = value != false;
        }

        return _notificationsEnabledCache as Boolean;
    }

    function setNotificationsEnabled(enabled as Boolean) as Void {
        writePropertyValue(PROP_NOTIFICATIONS_ENABLED, enabled);
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

    function deleteReadingByTime(originalTime as Number?) as Boolean {
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

        var count = BloodSugarPackedReading.getCount(bytes);
        var candidate = BloodSugarPackedReading.createHistory(count - 1);
        var destinationIndex = 0;

        for (var sourceIndex = 0; sourceIndex < count; sourceIndex += 1) {
            if (sourceIndex == readingIndex) {
                continue;
            }

            BloodSugarPackedReading.copy(
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
