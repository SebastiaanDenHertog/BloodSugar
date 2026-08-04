import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;

class BloodSugarSettingsDelegate extends WatchUi.BehaviorDelegate {
    const MODE_MAIN = 0;
    const MODE_ZONES = 1;

    const INDEX_UNIT = 0;
    const INDEX_ZONES = 1;
    const INDEX_MONITOR = 2;
    const INDEX_NOTIFICATIONS = 3;
    const INDEX_NOTIFICATION_LOW = 4;
    const INDEX_NOTIFICATION_HIGH = 5;
    const INDEX_CONTEXT = 6;
    const INDEX_CONFIRM = 7;
    const INDEX_CLEAR = 8;

    const MAIN_ITEM_COUNT = 9;
    const ZONE_ITEM_COUNT = 4;

    const ZONE_DANGER_LOW = 0;
    const ZONE_LOW = 1;
    const ZONE_HIGH = 2;
    const ZONE_DANGER_HIGH = 3;

    private var _view as BloodSugarSettingsView;

    private var _mode as Number;
    private var _selected as Number;
    private var _zoneSelected as Number;
    private var _editing as Boolean;
    private var _status as String;

    public function initialize(view as BloodSugarSettingsView) {
        BehaviorDelegate.initialize();

        _view = view;
        _mode = MODE_MAIN;
        _selected = INDEX_UNIT;
        _zoneSelected = ZONE_DANGER_LOW;
        _editing = false;
        _status = "";

        updateView();
    }

    public function onPreviousPage() as Boolean {
        _status = "";

        if (_editing) {
            changeEditedValue(1);
            updateView();

            return true;
        }

        if (_mode == MODE_ZONES) {
            _zoneSelected = wrapIndex(_zoneSelected - 1, ZONE_ITEM_COUNT);
        } else {
            _selected = wrapIndex(_selected - 1, MAIN_ITEM_COUNT);
        }

        updateView();

        return true;
    }

    public function onNextPage() as Boolean {
        _status = "";

        if (_editing) {
            changeEditedValue(-1);
            updateView();

            return true;
        }

        if (_mode == MODE_ZONES) {
            _zoneSelected = wrapIndex(_zoneSelected + 1, ZONE_ITEM_COUNT);
        } else {
            _selected = wrapIndex(_selected + 1, MAIN_ITEM_COUNT);
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
            updateView();
            return true;
        }

        if (_selected == INDEX_ZONES) {
            _mode = MODE_ZONES;
            _zoneSelected = ZONE_DANGER_LOW;
            updateView();
            return true;
        }

        if (_selected == INDEX_MONITOR) {
            openMonitorSetup();
            return true;
        }

        if (_selected == INDEX_NOTIFICATIONS) {
            BloodSugarStore.setNotificationsEnabled(
                !BloodSugarStore.getNotificationsEnabled()
            );
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
            updateView();
            return true;
        }

        if (_selected == INDEX_CLEAR) {
            var confirmation = new WatchUi.Confirmation("Delete all history?");
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
        var zones = BloodSugarStore.getBloodSugarZones();
        _view.setState(
            _mode,
            _selected,
            _zoneSelected,
            _editing,
            BloodSugarStore.getUseMgdl(),
            zones,
            BloodSugarStore.getNotificationsEnabled(),
            BloodSugarStore.getNotificationLowMmol(),
            BloodSugarStore.getNotificationHighMmol(),
            BloodSugarStore.getDefaultContextIndex(),
            BloodSugarStore.getConfirmBeforeSave(),
            _status
        );
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
