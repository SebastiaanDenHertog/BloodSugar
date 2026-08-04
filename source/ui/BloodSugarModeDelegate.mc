import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarModeDelegate extends WatchUi.BehaviorDelegate {
    private var _bleDelegate as BloodSugarServiceBleDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize(
        bleDelegate as BloodSugarServiceBleDelegate?,
        deviceManager as DeviceManager?
    ) {
        BehaviorDelegate.initialize();
        _bleDelegate = bleDelegate;
        _deviceManager = deviceManager;
    }

    public function onSelect() as Boolean {
        if (!BloodSugarStore.isBleSupported()) {
            System.println("BLE setup is hidden before version 1.0.0");
            return true;
        }

        if (_bleDelegate == null || _deviceManager == null) {
            System.println("BLE setup is not ready");
            return true;
        }

        var view = new BloodSugarSetupBleView();
        var delegate = new BloodSugarSetupBleDelegate(
            _bleDelegate as BloodSugarServiceBleDelegate,
            _deviceManager as DeviceManager,
            view
        );

        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
