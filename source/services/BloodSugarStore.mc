import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module BloodSugarStore {
    const MAX_POINTS = 240;

    const STORAGE_KEY = "BloodSugarHistory";

    const READING_TIME = 0;
    const READING_VALUE_MMOL = 1;
    const READING_SOURCE = 2;
    const READING_CONTEXT = 3;
    const READING_SCHEMA = 4;
    const CURRENT_READING_SCHEMA = 1;

    const PROP_APP_VERSION = "appVersion";
    const PROP_APP_CREATOR = "appCreator";
    const PROP_APP_NAME = "appName";
    const PROP_SETUP_DONE = "setupDone";
    const PROP_USE_MGDL = "useMgdl";
    const PROP_USE_BLOOD_MONITOR = "useBloodMonitor";
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

    function load() {
        var saved = Application.Storage.getValue(STORAGE_KEY);
        var migrated = false;

        if (!(saved instanceof Array)) {
            saved = Application.Storage.getValue(STORAGE_KEY);
            migrated = saved instanceof Array;
        }

        if (saved instanceof Array) {
            _history = saved;
        } else {
            _history = [];
        }

        normalizeHistory();

        if (migrated && save()) {
            Application.Storage.deleteValue(STORAGE_KEY);
        }

        return _history;
    }

    function normalizeHistory() as Void {
        if (_history == null) {
            _history = [];
            return;
        }

        var normalized = [];

        for (var i = 0; i < _history.size(); i++) {
            var reading = _history[i];

            if (!(reading instanceof Array) || reading.size() < 2) {
                continue;
            }

            var timestamp = reading[READING_TIME];
            var value = reading[READING_VALUE_MMOL];

            if (!(timestamp instanceof Number) || value == null) {
                continue;
            }

            var valueMmol = value.toFloat() as Float;

            if (valueMmol <= 0.0f) {
                continue;
            }

            var source = "manual";
            var context = "none";

            if (
                reading.size() > READING_SOURCE &&
                reading[READING_SOURCE] != null
            ) {
                source = reading[READING_SOURCE].toString();
            }

            if (
                reading.size() > READING_CONTEXT &&
                reading[READING_CONTEXT] != null
            ) {
                context = reading[READING_CONTEXT].toString();
            }

            normalized.add([
                timestamp,
                valueMmol,
                source,
                context,
                CURRENT_READING_SCHEMA,
            ]);
        }

        _history = normalized;

        if (_history.size() > MAX_POINTS) {
            _history = _history.slice(_history.size() - MAX_POINTS, null);
        }
    }

    function getHistory() {
        if (_history == null) {
            load();
        }

        return _history;
    }

    function getLatestReading() {
        var history = getHistory();

        if (history.size() == 0) {
            return null;
        }

        return history[history.size() - 1];
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

        var point = [
            Time.now().value(),
            valueMmol,
            inputSource,
            normalizeContext(context),
            CURRENT_READING_SCHEMA,
        ];

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
            Application.Storage.setValue(STORAGE_KEY, _history);
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
                reading.size() > READING_TIME &&
                reading[READING_TIME].toNumber() ==
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
                reading.size() > READING_TIME &&
                reading[READING_TIME].toNumber() == originalTime.toNumber()
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
            oldReading.size() > READING_SOURCE &&
            oldReading[READING_SOURCE] != null
        ) {
            source = oldReading[READING_SOURCE].toString();
        }

        var updatedReading = [
            oldReading[READING_TIME],
            valueMmol,
            source,
            normalizeContext(context),
            CURRENT_READING_SCHEMA,
        ];

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

    function getBloodMonitorText(useBloodMonitor) as String {
        if (useBloodMonitor) {
            return "Yes";
        }
        return "No";
    }

    function getUseMgdl() as Boolean {
        return Application.Properties.getValue(PROP_USE_MGDL) == true;
    }

    function setUseMgdl(useMgdl as Boolean) as Void {
        Application.Properties.setValue(PROP_USE_MGDL, useMgdl);
    }

    function getUseBloodMonitor() as Boolean {
        return Application.Properties.getValue(PROP_USE_BLOOD_MONITOR) == true;
    }

    function setUseBloodMonitor(useBloodMonitor as Boolean) as Void {
        Application.Properties.setValue(
            PROP_USE_BLOOD_MONITOR,
            useBloodMonitor
        );
    }

    function getRangePropertyMmol(
        propertyKey as String,
        defaultMgdl as Float
    ) as Float {
        var value = Application.Properties.getValue(propertyKey);

        if (value == null) {
            return MgdlToMoll(defaultMgdl);
        }

        return MgdlToMoll(value.toFloat());
    }

    function setRangePropertyMmol(
        propertyKey as String,
        valueMmol as Float
    ) as Void {
        Application.Properties.setValue(propertyKey, MollToMgdl(valueMmol));
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
        return Application.Properties.getValue(PROP_SETUP_DONE) == true;
    }

    function setSetupDone(done as Boolean) as Void {
        Application.Properties.setValue(PROP_SETUP_DONE, done);
    }

    function getConfirmBeforeSave() as Boolean {
        return Application.Properties.getValue(PROP_CONFIRM_SAVE) != false;
    }

    function setConfirmBeforeSave(confirm as Boolean) as Void {
        Application.Properties.setValue(PROP_CONFIRM_SAVE, confirm);
    }

    function getDefaultContextIndex() as Number {
        var value = Application.Properties.getValue(PROP_DEFAULT_CONTEXT);

        var index = value.toNumber();

        if (index < 0 || index >= getContextCount()) {
            return 0;
        }

        return index;
    }

    function setDefaultContextIndex(index as Number) as Void {
        Application.Properties.setValue(
            PROP_DEFAULT_CONTEXT,
            normalizeContextIndex(index)
        );
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

    function getAppCreator() as String {
        var value = Application.Properties.getValue(PROP_APP_CREATOR);

        return value.toString();
    }

    function getAppName() as String {
        var value = Application.Properties.getValue(PROP_APP_NAME);

        return value.toString();
    }

    function getAppVersion() as String {
        var value = Application.Properties.getValue(PROP_APP_VERSION);

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

            var point = [
                timestamp,
                valueMmol,
                source,
                normalizeContext(context),
                CURRENT_READING_SCHEMA,
            ];

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
                reading.size() > READING_TIME &&
                reading[READING_TIME] != null &&
                reading[READING_TIME].toNumber() == timestamp
            ) {
                return true;
            }
        }

        return false;
    }

    function insertReadingSorted(history, point) as Void {
        var pointTime = point[READING_TIME].toNumber();
        var insertionIndex = history.size();

        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (
                reading instanceof Array &&
                reading.size() > READING_TIME &&
                reading[READING_TIME] != null &&
                reading[READING_TIME].toNumber() > pointTime
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

        var value = Application.Properties.getValue(PROP_CUSTOM_CONTEXTS);

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

    public function setBloodMonitor(selected as Number) {
        Application.Properties.setValue(PROP_BLOOD_MONITOR_INDEX, selected);
    }

    public function getBloodMonitor() as Number? {
        return Application.Properties.getValue(
            PROP_BLOOD_MONITOR_INDEX
        ).toNumber();
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
        return (
            Application.Properties.getValue(PROP_NOTIFICATIONS_ENABLED) != false
        );
    }

    function setNotificationsEnabled(enabled as Boolean) as Void {
        Application.Properties.setValue(PROP_NOTIFICATIONS_ENABLED, enabled);
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
}
