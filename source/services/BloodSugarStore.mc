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
    const MAX_POINTS = 240;

    const STORAGE_KEY = "BloodSugarHistory";
    const PROP_APP_VERSION = "appVersion";
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

    const NOTIFICATION_NONE = 0;
    const NOTIFICATION_LOW = 1;
    const NOTIFICATION_HIGH = 2;

    var _history = null;
    var _historyNeedsRepair = false;

    const MONITOR_NONE = 0;
    const MONITOR_ABBOTT = 1;
    const MONITOR_BLE = 2;

    function load() {
        var saved = null;

        try {
            saved = Storage.getValue(STORAGE_KEY);
        } catch (error) {
            _history = [] as Array;
            _historyNeedsRepair = false;
            return _history;
        }
        if (!(saved instanceof Array)) {
            _history = [] as Array;
            _historyNeedsRepair = false;
            return _history;
        }
        var loadedHistory = [] as Array<Storage.ValueType>;
        _historyNeedsRepair = false;
        if (!(saved instanceof Array)) {
            _history = loadedHistory;
            return _history;
        }
        var storedHistory = saved as Array;
        for (var index = 0; index < storedHistory.size(); index += 1) {
            var rawReading = storedHistory[index];
            var normalizedReading = BloodSugarReading.normalize(
                rawReading,
                index
            );
            if (normalizedReading == null) {
                _historyNeedsRepair = true;
                continue;
            }
            if (!BloodSugarReading.isCurrent(rawReading)) {
                _historyNeedsRepair = true;
            }
            loadedHistory.add(normalizedReading);
        }
        _history = loadedHistory;

        if (_history.size() != storedHistory.size()) {
            _historyNeedsRepair = true;
        }

        return _history;
    }

    function historyNeedsRepair() as Boolean {
        return _historyNeedsRepair;
    }

    function persistHistoryRepair() as Boolean {
        if (!_historyNeedsRepair) {
            return true;
        }

        if (_history == null) {
            return false;
        }

        if (!save()) {
            return false;
        }
        _historyNeedsRepair = false;
        return true;
    }

    function normalizeHistory() as Void {
        var normalized = [] as Array;

        for (var index = 0; index < _history.size(); index += 1) {
            var item = _history[index];

            if (!(item instanceof Array)) {
                continue;
            }

            var reading = item as Array;

            if (reading.size() < 4) {
                continue;
            }

            normalized.add(reading);
        }

        _history = normalized;
    }

    function toStoredFloat(value) as Float? {
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

    function getHistory() {
        if (_history == null) {
            load();
        }

        return _history;
    }

    function getPartOfHistory(items as Number) as Array<Object?> {
        var history = getHistory();

        if (history.size() == 0) {
            return null;
        }

        if (items > history.size()) {
            items = history.size();
        }

        history = history.slice(history.size() - items, history.size());

        return history;
    }

    function getLatestReading() as Array or Dictionary or Null {
        var history = getHistory();
        if (history == null) {
            return null;
        }
        var count = history.size();
        if (count == 0) {
            return null;
        }
        var index = count - 1;
        var reading = history[index];
        return reading;
    }

    function addReading(
        valueMmol as Float,
        inputSource as String,
        context as String
    ) as Boolean {
        if (valueMmol <= 0.0f) {
            return false;
        }

        if (_history == null) {
            load();
        }

        var point = BloodSugarReading.create(
            Time.now().value(),
            valueMmol,
            inputSource,
            normalizeContext(context)
        );

        var previousHistory = _history;
        var candidateHistory = _history.slice(0, null);
        candidateHistory.add(point);

        if (candidateHistory.size() > MAX_POINTS) {
            candidateHistory = candidateHistory.slice(
                candidateHistory.size() - MAX_POINTS,
                null
            );
        }

        _history = candidateHistory;

        if (save()) {
            return true;
        }

        _history = previousHistory;
        return false;
    }

    function save() as Boolean {
        if (_history == null) {
            return false;
        }

        try {
            Storage.setValue(STORAGE_KEY, _history);
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
        var data = getHistory();
        for (var i = 0; i < data.size(); i++) {
            var reading = data[i];

            if (
                reading != null &&
                reading.size() > BloodSugarReading.TIME &&
                reading[BloodSugarReading.TIME].toNumber() ==
                    bloodSugarValueTime.toNumber()
            ) {
                return reading;
            }
        }

        return null;
    }

    function updateReadingByTime(
        originalTime,
        valueMmol as Float,
        context as String
    ) as Boolean {
        if (originalTime == null || valueMmol <= 0.0f) {
            return false;
        }

        var history = getHistory();
        var readingIndex = -1;

        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (
                reading != null &&
                reading.size() > BloodSugarReading.TIME &&
                reading[BloodSugarReading.TIME].toNumber() ==
                    originalTime.toNumber()
            ) {
                readingIndex = i;
                break;
            }
        }

        if (readingIndex < 0) {
            return false;
        }

        var oldReading = history[readingIndex];
        var source = "manual";
        if (
            oldReading.size() > BloodSugarReading.SOURCE &&
            oldReading[BloodSugarReading.SOURCE] != null
        ) {
            source = oldReading[BloodSugarReading.SOURCE].toString();
        }

        var updatedReading = BloodSugarReading.create(
            oldReading[BloodSugarReading.TIME].toNumber(),
            valueMmol,
            source,
            normalizeContext(context)
        );

        var previousHistory = _history;
        var candidateHistory = history.slice(0, null);

        candidateHistory[readingIndex] = updatedReading;

        _history = candidateHistory;

        if (save()) {
            return true;
        }

        _history = previousHistory;
        return false;
    }

    function clear() as Boolean {
        var previousHistory = getHistory();
        _history = [];

        if (save()) {
            return true;
        }

        _history = previousHistory;
        return false;
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
                break;
            case MONITOR_ABBOTT:
                return "Abbott FreeStyle";
                break;
            //case MONITOR_BLE:
            //return "Ble Monitor";
            //    break;
        }
    }

    function getUseMgdl() as Boolean {
        return Properties.getValue(PROP_USE_MGDL) == true;
    }

    function setUseMgdl(useMgdl as Boolean) as Void {
        Properties.setValue(PROP_USE_MGDL, useMgdl);
    }

    function getRangePropertyMmol(
        propertyKey as String,
        defaultMgdl as Float
    ) as Float {
        var value = Properties.getValue(propertyKey);

        if (value == null) {
            return MgdlToMoll(defaultMgdl);
        }

        return MgdlToMoll(value.toFloat());
    }

    function setRangePropertyMmol(
        propertyKey as String,
        valueMmol as Float
    ) as Void {
        Properties.setValue(propertyKey, MollToMgdl(valueMmol));
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

    function getBloodSugarZones() {
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

        return [dangerLow, low, high, dangerHigh];
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
        return Properties.getValue(PROP_CONFIRM_SAVE) != false;
    }

    function setConfirmBeforeSave(confirm as Boolean) as Void {
        Properties.setValue(PROP_CONFIRM_SAVE, confirm);
    }

    function getDefaultContextIndex() as Number {
        var value = Properties.getValue(PROP_DEFAULT_CONTEXT);

        var index = value.toNumber();

        if (index < 0 || index >= getContextCount()) {
            return 0;
        }

        return index;
    }

    function setDefaultContextIndex(index as Number) as Void {
        Properties.setValue(PROP_DEFAULT_CONTEXT, normalizeContextIndex(index));
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

        for (var i = 0; i < maxLen; i++) {
            var versionNum = 0 as Number;
            var minVersionNum = 0 as Number;

            if (i < versionParts.size() && versionParts[i].length() > 0) {
                versionNum = versionParts[i].toNumber();
            }

            if (i < minVersionParts.size() && minVersionParts[i].length() > 0) {
                minVersionNum = minVersionParts[i].toNumber();
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
        return isSupportedVersion(getAppVersion(), "1.0.0");
    }

    function addReadingsBatch(readings) as Number {
        if (!(readings instanceof Array)) {
            return -1;
        }

        if (_history == null) {
            load();
        }

        var previousHistory = _history;
        var candidateHistory = _history.slice(0, null);
        var addedCount = 0;

        for (var i = 0; i < readings.size(); i++) {
            var incoming = readings[i];

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

            if (timestamp <= 0 || valueMmol <= 0.0f) {
                continue;
            }

            if (historyContainsTime(candidateHistory, timestamp)) {
                continue;
            }

            var point = BloodSugarReading.create(
                timestamp,
                valueMmol,
                source,
                normalizeContext(context)
            );

            insertReadingSorted(candidateHistory, point);
            addedCount += 1;
        }

        if (addedCount == 0) {
            return 0;
        }

        if (candidateHistory.size() > MAX_POINTS) {
            candidateHistory = candidateHistory.slice(
                candidateHistory.size() - MAX_POINTS,
                null
            );
        }

        _history = candidateHistory;

        if (save()) {
            return addedCount;
        }

        _history = previousHistory;
        return -1;
    }

    function hasReadingByTime(timestamp as Number) as Boolean {
        return historyContainsTime(getHistory(), timestamp);
    }

    function historyContainsTime(history, timestamp as Number) as Boolean {
        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (
                reading instanceof Array &&
                reading.size() > BloodSugarReading.TIME &&
                reading[BloodSugarReading.TIME] != null &&
                reading[BloodSugarReading.TIME].toNumber() == timestamp
            ) {
                return true;
            }
        }

        return false;
    }

    function insertReadingSorted(history, point) as Void {
        var pointTime = point[BloodSugarReading.TIME].toNumber();
        var insertionIndex = history.size();

        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (
                reading instanceof Array &&
                reading.size() > BloodSugarReading.TIME &&
                reading[BloodSugarReading.TIME] != null &&
                reading[BloodSugarReading.TIME].toNumber() > pointTime
            ) {
                insertionIndex = i;
                break;
            }
        }

        history.add(point);

        for (var j = history.size() - 1; j > insertionIndex; j--) {
            history[j] = history[j - 1];
        }

        history[insertionIndex] = point;
    }

    function getCustomContextNames() as Array<String> {
        var names = [] as Array<String>;

        var value = Properties.getValue(PROP_CUSTOM_CONTEXTS);

        if (!(value instanceof Array)) {
            return names;
        }

        var contexts = value as Array;

        for (var index = 0; index < contexts.size(); index++) {
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
        return ["Abbott FreeStyle"] as Array<String>;
    }

    public function setBloodMonitor(selected as Number) as Void {
        Properties.setValue(PROP_BLOOD_MONITOR_INDEX, selected);
    }

    public function getBloodMonitor() as Number {
        var value = Properties.getValue(PROP_BLOOD_MONITOR_INDEX);

        if (value instanceof Number) {
            return value as Number;
        }

        return BloodSugarMonitor.NONE;
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
        return Properties.getValue(PROP_NOTIFICATIONS_ENABLED) != false;
    }

    function setNotificationsEnabled(enabled as Boolean) as Void {
        Properties.setValue(PROP_NOTIFICATIONS_ENABLED, enabled);
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

        var history = getHistory();
        var readingIndex = -1;

        for (var i = 0; i < history.size(); i += 1) {
            var reading = history[i];

            if (
                reading instanceof Array &&
                reading.size() > BloodSugarReading.TIME &&
                reading[BloodSugarReading.TIME] != null &&
                reading[BloodSugarReading.TIME].toNumber() ==
                    originalTime.toNumber()
            ) {
                readingIndex = i;
                break;
            }
        }

        if (readingIndex < 0) {
            return false;
        }

        var previousHistory = _history;
        var candidateHistory = [] as Array;

        for (var index = 0; index < history.size(); index += 1) {
            if (index != readingIndex) {
                candidateHistory.add(history[index]);
            }
        }

        _history = candidateHistory;

        if (save()) {
            return true;
        }

        /*
         * Saving failed, so restore the
         * history we had before deletion.
         */
        _history = previousHistory;

        return false;
    }
}
