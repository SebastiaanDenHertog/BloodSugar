import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BloodSugarSetupDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupView?;
    private var _bleDelegate as BloodSugarServiceDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize(
        bleDelegate as BloodSugarServiceDelegate,
        deviceManager as DeviceManager
    ) {
        BehaviorDelegate.initialize();
        _bleDelegate = bleDelegate;
        _deviceManager = deviceManager;
    }

    public function onMenu() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    public function onNextPage() as Boolean {
        // Trigger search
        if (_deviceManager != null) {
            _view.setIsScanning(true);
            _deviceManager.start();
        }
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    // Callback from DeviceManager when a device is found
    public function onDeviceFound(result as ScanResult) as Void {
        var name = result.getDeviceName();
        _view.setDeviceName(name);
        _view.setStatus("Found: " + name);

        // Show confirmation dialog using Attention API
        var dialog = new WatchUi.Confirmation("Connect to " + name + "?");
        WatchUi.pushView(
            dialog,
            new ConfirmationDelegate(),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    private function handleConfirm(confirm as Boolean) as Void {
        if (confirm && _deviceManager != null) {
            _view.setStatus("Connecting...");
            // TODO: Implement connection logic here
        } else {
            _view.setIsScanning(false);
            _view.setStatus("Search Cancelled");
        }
    }

    public function setView(view as BloodSugarSetupView) as Void {
        _view = view;
    }
}
