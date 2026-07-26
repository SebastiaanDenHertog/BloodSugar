import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSettingsDelegate extends WatchUi.BehaviorDelegate {
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

        if (BloodSugarStore.isBleSupported() && _selected == 5) {
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
            return 7;
        }

        return 6;
    }

    private function getClearIndex() as Number {
        return getItemCount() - 1;
    }

    private function changeCurrentValue(direction as Number) as Void {
        _status = "";

        if (_selected == 0) {
            BloodSugarStore.setUseMgdl(!BloodSugarStore.getUseMgdl());
        } else if (_selected == 1) {
            adjustTargetLow(direction);
        } else if (_selected == 2) {
            adjustTargetHigh(direction);
        } else if (_selected == 3) {
            BloodSugarStore.setDefaultContextIndex(
                BloodSugarStore.getDefaultContextIndex() + direction
            );
        } else if (_selected == 4) {
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

    private function adjustTargetLow(direction as Number) as Void {
        var step = getTargetStepMmol();
        var value = BloodSugarStore.getTargetLowMmol() + step * direction;
        var high = BloodSugarStore.getTargetHighMmol();

        if (value < 0.1f) {
            value = 0.1f;
        }

        if (value >= high) {
            value = high - step;
        }

        BloodSugarStore.setTargetLowMmol(value);
    }

    private function adjustTargetHigh(direction as Number) as Void {
        var step = getTargetStepMmol();
        var value = BloodSugarStore.getTargetHighMmol() + step * direction;
        var low = BloodSugarStore.getTargetLowMmol();

        if (value <= low) {
            value = low + step;
        }

        if (value > 50.0f) {
            value = 50.0f;
        }

        BloodSugarStore.setTargetHighMmol(value);
    }

    private function getTargetStepMmol() as Float {
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
        _view.setState(
            _selected,
            BloodSugarStore.getUseMgdl(),
            BloodSugarStore.getTargetLowMmol(),
            BloodSugarStore.getTargetHighMmol(),
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
