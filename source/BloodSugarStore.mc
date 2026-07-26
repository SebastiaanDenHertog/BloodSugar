import Toybox.Application;
import Toybox.Time;
import Toybox.System;
import Toybox.Lang;

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
    const PROP_SETUP_DONE = "setupDone";
    const PROP_USE_MGDL = "useMgdl";
    const PROP_TARGET_LOW = "targetLowMmol";
    const PROP_TARGET_HIGH = "targetHighMmol";
    const PROP_DEFAULT_CONTEXT = "defaultContextIndex";
    const PROP_CONFIRM_SAVE = "confirmBeforeSave";

    var _history = null;

    function load() {
        var saved = Storage.getValue(STORAGE_KEY);
        var migrated = false;

        if (!(saved instanceof Array)) {
            saved = Storage.getValue(STORAGE_KEY);
            migrated = saved instanceof Array;
        }

        if (saved instanceof Array) {
            _history = saved;
        } else {
            _history = [];
        }

        normalizeHistory();

        if (migrated && save()) {
            Storage.deleteValue(STORAGE_KEY);
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

            var valueMmol = value.toFloat();

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
            Storage.setValue(STORAGE_KEY, _history);
            return true;
        } catch (error) {
            System.println("Could not save glucose history: " + error);
            return false;
        }
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

    function getUseMgdl() as Boolean {
        return Application.Properties.getValue(PROP_USE_MGDL) == true;
    }

    function setUseMgdl(useMgdl as Boolean) as Void {
        Application.Properties.setValue(PROP_USE_MGDL, useMgdl);
    }

    function getTargetLowMmol() as Float {
        var value = Application.Properties.getValue(PROP_TARGET_LOW);

        if (value == null) {
            return 4.0f;
        }

        return value.toFloat();
    }

    function setTargetLowMmol(value as Float) as Void {
        Application.Properties.setValue(PROP_TARGET_LOW, value);
    }

    function getTargetHighMmol() as Float {
        var value = Application.Properties.getValue(PROP_TARGET_HIGH);

        if (value == null) {
            return 10.0f;
        }

        return value.toFloat();
    }

    function setTargetHighMmol(value as Float) as Void {
        Application.Properties.setValue(PROP_TARGET_HIGH, value);
    }

    function getBloodSugarZones() {
        var low = getTargetLowMmol();
        var high = getTargetHighMmol();
        var dangerLow = low - 1.0f;

        if (dangerLow < 0.0f) {
            dangerLow = 0.0f;
        }

        return [dangerLow, low, high, high + 3.0f];
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

        if (value == null) {
            return 0;
        }

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

    function getAppVersion() as String {
        var value = Application.Properties.getValue(PROP_APP_VERSION);

        if (value == null) {
            return "0.0.0";
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

        for (var i = 0; i < maxLen; i++) {
            var versionNum = 0;
            var minVersionNum = 0;

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
}
