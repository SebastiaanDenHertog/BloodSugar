import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSettingsDelegate extends WatchUi.BehaviorDelegate {
    const INDEX_UNIT = 0;
    const INDEX_DANGER_LOW = 1;
    const INDEX_LOW = 2;
    const INDEX_HIGH = 3;
    const INDEX_DANGER_HIGH = 4;
    const INDEX_CONTEXT = 5;
    const INDEX_CONFIRM = 6;
    const INDEX_BLE = 7;

    private var _view as BloodSugarSettingsView;
    private var _selected as Number;
    private var _status as String;

    public function initialize(view as BloodSugarSettingsView) {
        BehaviorDelegate.initialize();
        _view = view;
        _selected = 0;
        _status = "";
        updateView();
    }

    public function onPreviousPage() as Boolean {
        changeCurrentValue(1);
        return true;
    }

    public function onNextPage() as Boolean {
        changeCurrentValue(-1);
        return true;
    }

    public function onSelect() as Boolean {
        _status = "";

        if (BloodSugarStore.isBleSupported() && _selected == INDEX_BLE) {
            openBleSetup();
            return true;
        }

        if (_selected == getClearIndex()) {
            var confirmation = new WatchUi.Confirmation("Delete all history?");
            WatchUi.pushView(
                confirmation,
                new BloodSugarClearConfirmationDelegate(self),
                WatchUi.SLIDE_IMMEDIATE
            );
            return true;
        }

        _selected += 1;

        if (_selected >= getItemCount()) {
            _selected = 0;
        }

        updateView();
        return true;
    }

    public function onBack() as Boolean {
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

    private function getItemCount() as Number {
        if (BloodSugarStore.isBleSupported()) {
            return 9;
        }

        return 8;
    }

    private function getClearIndex() as Number {
        return getItemCount() - 1;
    }

    private function changeCurrentValue(direction as Number) as Void {
        _status = "";

        if (_selected == INDEX_UNIT) {
            BloodSugarStore.setUseMgdl(!BloodSugarStore.getUseMgdl());
        } else if (
            _selected >= INDEX_DANGER_LOW &&
            _selected <= INDEX_DANGER_HIGH
        ) {
            adjustThreshold(_selected, direction);
        } else if (_selected == INDEX_CONTEXT) {
            BloodSugarStore.setDefaultContextIndex(
                BloodSugarStore.getDefaultContextIndex() + direction
            );
        } else if (_selected == INDEX_CONFIRM) {
            BloodSugarStore.setConfirmBeforeSave(
                !BloodSugarStore.getConfirmBeforeSave()
            );
        } else {
            _selected += direction;

            while (_selected < 0) {
                _selected += getItemCount();
            }

            while (_selected >= getItemCount()) {
                _selected -= getItemCount();
            }
        }

        updateView();
    }

    private function adjustThreshold(
        selectedIndex as Number,
        direction as Number
    ) as Void {
        var zones = BloodSugarStore.getBloodSugarZones();
        var step = getThresholdStepMmol();
        var value =
            zones[selectedIndex - INDEX_DANGER_LOW].toFloat() +
            step * direction;

        if (selectedIndex == INDEX_DANGER_LOW) {
            if (value < step) {
                value = step;
            }
            if (value >= zones[1].toFloat()) {
                value = zones[1].toFloat() - step;
            }
            BloodSugarStore.setDangerLowMmol(value);
            return;
        }

        if (selectedIndex == INDEX_LOW) {
            if (value <= zones[0].toFloat()) {
                value = zones[0].toFloat() + step;
            }
            if (value >= zones[2].toFloat()) {
                value = zones[2].toFloat() - step;
            }
            BloodSugarStore.setLowMmol(value);
            return;
        }

        if (selectedIndex == INDEX_HIGH) {
            if (value <= zones[1].toFloat()) {
                value = zones[1].toFloat() + step;
            }
            if (value >= zones[3].toFloat()) {
                value = zones[3].toFloat() - step;
            }
            BloodSugarStore.setHighMmol(value);
            return;
        }

        if (value <= zones[2].toFloat()) {
            value = zones[2].toFloat() + step;
        }
        if (value > 50.0f) {
            value = 50.0f;
        }
        BloodSugarStore.setDangerHighMmol(value);
    }

    private function getThresholdStepMmol() as Float {
        if (BloodSugarStore.getUseMgdl()) {
            return BloodSugarStore.MgdlToMoll(1.0f);
        }

        return 0.1f;
    }

    private function openBleSetup() as Void {
        var app = Application.getApp() as BloodSugarApp;
        var bleDelegate = app.getBleDelegate();
        var deviceManager = app.getDeviceManager();

        if (bleDelegate == null || deviceManager == null) {
            _status = "BLE is not ready";
            updateView();
            return;
        }

        var view = new BloodSugarSetupBleView();
        var delegate = new BloodSugarSetupBleDelegate(
            bleDelegate as BloodSugarServiceBleDelegate,
            deviceManager as DeviceManager,
            view
        );

        WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
    }

    private function updateView() as Void {
        var zones = BloodSugarStore.getBloodSugarZones();

        _view.setState(
            _selected,
            BloodSugarStore.getUseMgdl(),
            zones,
            BloodSugarStore.getDefaultContextIndex(),
            BloodSugarStore.getConfirmBeforeSave(),
            BloodSugarStore.isBleSupported(),
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
