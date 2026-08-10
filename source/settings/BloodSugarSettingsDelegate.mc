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

import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;

class BloodSugarSettingsDelegate extends WatchUi.BehaviorDelegate {
    const ZONE_ITEM_COUNT = 4;

    const ZONE_DANGER_LOW = 0;
    const ZONE_LOW = 1;
    const ZONE_HIGH = 2;
    const ZONE_DANGER_HIGH = 3;

    const MODE_MAIN = 0;
    const MODE_ZONES = 1;

    /*
     * GENERAL
     */
    const INDEX_UNIT = 0;
    const INDEX_ZONES = 1;
    const INDEX_CONTEXT = 2;
    const INDEX_CONFIRM = 3;

    /*
     * MONITOR
     */
    const INDEX_MONITOR = 4;

    /*
     * NOTIFICATIONS
     */
    const INDEX_NOTIFICATIONS = 5;
    const INDEX_NOTIFICATION_LOW = 6;
    const INDEX_NOTIFICATION_HIGH = 7;

    /*
     * DANGER
     */
    const INDEX_CLEAR = 8;
    const MAIN_ITEM_COUNT = 9;

    private var _view as BloodSugarSettingsView;
    private var _mode as Number;
    private var _selected as Number;
    private var _zoneSelected as Number;
    private var _editing as Boolean;
    private var _status as String;
    private var _savedMode as Number;
    private var _savedIndex as Number;

    public function initialize(view as BloodSugarSettingsView) {
        BehaviorDelegate.initialize();
        _view = view;
        _mode = MODE_MAIN;
        _selected = INDEX_UNIT;
        _zoneSelected = ZONE_DANGER_LOW;
        _editing = false;
        _status = "";
        _savedMode = -1;
        _savedIndex = -1;
        updateView();
    }

    public function onPreviousPage() as Boolean {
        _status = "";

        if (_editing) {
            clearSavedState();
            changeEditedValue(1);
            markSaved(_mode, _mode == MODE_ZONES ? _zoneSelected : _selected);
            updateView();
            return true;
        }
        clearSavedState();
        if (_mode == MODE_ZONES) {
            if (_zoneSelected > 0) {
                _zoneSelected -= 1;
            }
        } else {
            if (_selected > 0) {
                _selected -= 1;
            }
        }
        updateView();
        return true;
    }

    private function markSaved(mode as Number, index as Number) as Void {
        _savedMode = mode;
        _savedIndex = index;
        _status = "Saved";
    }

    private function clearSavedState() as Void {
        _savedMode = -1;
        _savedIndex = -1;

        if (_status.equals("Saved")) {
            _status = "";
        }
    }

    public function onNextPage() as Boolean {
        _status = "";

        if (_editing) {
            clearSavedState();
            changeEditedValue(-1);
            markSaved(_mode, _mode == MODE_ZONES ? _zoneSelected : _selected);
            updateView();
            return true;
        }

        clearSavedState();
        if (_mode == MODE_ZONES) {
            if (_zoneSelected < ZONE_ITEM_COUNT - 1) {
                _zoneSelected += 1;
            }
        } else {
            if (_selected < MAIN_ITEM_COUNT - 1) {
                _selected += 1;
            }
        }

        updateView();
        return true;
    }

    public function onSelect() as Boolean {
        _status = "";

        if (_editing) {
            _editing = false;
            updateView();
            return true;
        }

        if (_mode == MODE_ZONES) {
            _editing = true;
            updateView();
            return true;
        }

        if (_selected == INDEX_UNIT) {
            BloodSugarStore.setUseMgdl(!BloodSugarStore.getUseMgdl());
            markSaved(MODE_MAIN, INDEX_UNIT);
            updateView();
            return true;
        }

        if (_selected == INDEX_ZONES) {
            _mode = MODE_ZONES;
            _zoneSelected = ZONE_DANGER_LOW;
            clearSavedState();
            updateView();
            return true;
        }

        if (_selected == INDEX_MONITOR) {
            clearSavedState();
            openMonitorSetup();
            return true;
        }

        if (_selected == INDEX_NOTIFICATIONS) {
            BloodSugarStore.setNotificationsEnabled(
                !BloodSugarStore.getNotificationsEnabled()
            );
            markSaved(MODE_MAIN, INDEX_NOTIFICATIONS);
            updateView();
            return true;
        }

        if (
            _selected == INDEX_NOTIFICATION_LOW ||
            _selected == INDEX_NOTIFICATION_HIGH ||
            _selected == INDEX_CONTEXT
        ) {
            _editing = true;
            updateView();
            return true;
        }

        if (_selected == INDEX_CONFIRM) {
            BloodSugarStore.setConfirmBeforeSave(
                !BloodSugarStore.getConfirmBeforeSave()
            );
            markSaved(MODE_MAIN, INDEX_CONFIRM);
            updateView();
            return true;
        }

        if (_selected == INDEX_CLEAR) {
            var confirmation = new WatchUi.Confirmation("Delete all history?");
            clearSavedState();
            WatchUi.pushView(
                confirmation,
                new BloodSugarClearConfirmationDelegate(self),
                WatchUi.SLIDE_IMMEDIATE
            );

            return true;
        }

        return false;
    }

    public function onBack() as Boolean {
        if (_editing) {
            _editing = false;
            updateView();
            return true;
        }
        if (_mode == MODE_ZONES) {
            _mode = MODE_MAIN;
            updateView();
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onMenu() as Boolean {
        return onBack();
    }

    public function handleClearResponse(confirm as Boolean) as Void {
        if (confirm) {
            if (BloodSugarStore.clear()) {
                _status = "History deleted";
            } else {
                _status = "Could not delete history";
            }
        }
        updateView();
    }

    private function changeEditedValue(direction as Number) as Void {
        if (_mode == MODE_ZONES) {
            adjustZoneThreshold(_zoneSelected, direction);
            return;
        }
        if (_selected == INDEX_NOTIFICATION_LOW) {
            adjustNotificationLow(direction);
            return;
        }
        if (_selected == INDEX_NOTIFICATION_HIGH) {
            adjustNotificationHigh(direction);
            return;
        }
        if (_selected == INDEX_CONTEXT) {
            BloodSugarStore.setDefaultContextIndex(
                BloodSugarStore.getDefaultContextIndex() + direction
            );
        }
    }

    private function adjustZoneThreshold(
        selectedIndex as Number,
        direction as Number
    ) as Void {
        var zones = BloodSugarStore.getBloodSugarZones();
        var step = getThresholdStepMmol();
        var value = zones[selectedIndex].toFloat() + step * direction;
        if (selectedIndex == ZONE_DANGER_LOW) {
            if (value < step) {
                value = step;
            }
            if (value >= zones[ZONE_LOW].toFloat()) {
                value = zones[ZONE_LOW].toFloat() - step;
            }
            BloodSugarStore.setDangerLowMmol(value);
            return;
        }

        if (selectedIndex == ZONE_LOW) {
            if (value <= zones[ZONE_DANGER_LOW].toFloat()) {
                value = zones[ZONE_DANGER_LOW].toFloat() + step;
            }
            if (value >= zones[ZONE_HIGH].toFloat()) {
                value = zones[ZONE_HIGH].toFloat() - step;
            }
            BloodSugarStore.setLowMmol(value);
            return;
        }
        if (selectedIndex == ZONE_HIGH) {
            if (value <= zones[ZONE_LOW].toFloat()) {
                value = zones[ZONE_LOW].toFloat() + step;
            }
            if (value >= zones[ZONE_DANGER_HIGH].toFloat()) {
                value = zones[ZONE_DANGER_HIGH].toFloat() - step;
            }
            BloodSugarStore.setHighMmol(value);
            return;
        }
        if (value <= zones[ZONE_HIGH].toFloat()) {
            value = zones[ZONE_HIGH].toFloat() + step;
        }
        if (value > 50.0f) {
            value = 50.0f;
        }

        BloodSugarStore.setDangerHighMmol(value);
    }

    private function adjustNotificationLow(direction as Number) as Void {
        var step = getThresholdStepMmol();
        var low = BloodSugarStore.getNotificationLowMmol() + step * direction;
        var high = BloodSugarStore.getNotificationHighMmol();
        if (low < step) {
            low = step;
        }

        if (low >= high) {
            low = high - step;
        }

        BloodSugarStore.setNotificationLowMmol(low);
    }

    private function adjustNotificationHigh(direction as Number) as Void {
        var step = getThresholdStepMmol();
        var low = BloodSugarStore.getNotificationLowMmol();
        var high = BloodSugarStore.getNotificationHighMmol() + step * direction;
        if (high <= low) {
            high = low + step;
        }
        if (high > 50.0f) {
            high = 50.0f;
        }
        BloodSugarStore.setNotificationHighMmol(high);
    }

    private function getThresholdStepMmol() as Float {
        if (BloodSugarStore.getUseMgdl()) {
            return BloodSugarStore.MgdlToMoll(1.0f);
        }
        return 0.1f;
    }

    private function openMonitorSetup() as Void {
        var monitorView = new BloodSugarSetupMonitorView();
        var monitorDelegate = new BloodSugarSetupMonitorDelegate(monitorView);
        WatchUi.pushView(monitorView, monitorDelegate, WatchUi.SLIDE_LEFT);
    }

    private function wrapIndex(index as Number, itemCount as Number) as Number {
        while (index < 0) {
            index += itemCount;
        }
        while (index >= itemCount) {
            index -= itemCount;
        }
        return index;
    }

    private function updateView() as Void {
        var state = new SettingsState();
        state.mode = _mode;
        state.selected = _selected;
        state.zoneSelected = _zoneSelected;
        state.editing = _editing;
        state.useMgdl = BloodSugarStore.getUseMgdl();
        state.zones = BloodSugarStore.getBloodSugarZones();
        state.notificationsEnabled = BloodSugarStore.getNotificationsEnabled();
        state.notificationLowMmol = BloodSugarStore.getNotificationLowMmol();
        state.notificationHighMmol = BloodSugarStore.getNotificationHighMmol();
        state.contextIndex = BloodSugarStore.getDefaultContextIndex();
        state.confirmBeforeSave = BloodSugarStore.getConfirmBeforeSave();
        state.status = _status;
        state.savedMode = _savedMode;
        state.savedIndex = _savedIndex;
        _view.setState(state);
    }
}

class BloodSugarClearConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var _parent as BloodSugarSettingsDelegate;
    public function initialize(parent as BloodSugarSettingsDelegate) {
        ConfirmationDelegate.initialize();
        _parent = parent;
    }

    public function onResponse(response as WatchUi.Confirm) as Boolean {
        _parent.handleClearResponse(response == WatchUi.CONFIRM_YES);
        return true;
    }
}
