import Toybox.Application;
import Toybox.Time;
import Toybox.System;
import Toybox.Lang;

module BloodSugarStore {
    const MAX_POINTS = 240;

    const STORAGE_KEY = "BloodSugerHistory";

    var _history = null;

    function load() {
        var saved = Storage.getValue(STORAGE_KEY);

        if (saved instanceof Array) {
            _history = saved;
        } else {
            _history = [];
        }

        return _history;
    }

    function getHistory() {
        if (_history == null) {
            load();
        }

        return _history;
    }

    function addReading(value) {
        if (_history == null) {
            load();
        }

        var timestamp = Time.now().value();

        var point = [timestamp, value];

        _history.add(point);

        if (_history.size() > MAX_POINTS) {
            _history = _history.slice(_history.size() - MAX_POINTS, null);
        }

        save();
    }

    function save() {
        if (_history == null) {
            return;
        }

        try {
            Storage.setValue(STORAGE_KEY, _history);
        } catch (error) {
            System.println("Could not save glucose history: " + error);
        }
    }

    function clear() {
        _history = [];
        Storage.setValue(STORAGE_KEY, _history);
    }

    // from 8 to 144.125
    function MollToMgdl(Moll) as Float {
        return Moll * 18.018;
    }

    // from 144.125 to 8
    function MgdlToMoll(Mgdl) as Float {
        return Mgdl / 18.018;
    }

    function getBloodSugarZones() {
        return [
            Application.Properties.getValue("dangerLow"),
            Application.Properties.getValue("Low"),
            Application.Properties.getValue("High"),
            Application.Properties.getValue("dangerHigh"),
        ];
    }

    function getDiabeteMode() {
        return Application.Properties.getValue("diabeteMode") as Boolean;
    }

    function getSetupDone() {
        return Application.Properties.getValue("setupDone") as Boolean;
    }
}
