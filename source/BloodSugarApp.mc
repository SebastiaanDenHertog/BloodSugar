import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {
    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarServiceBleDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        BloodSugarStore.load();

        if (!BloodSugarStore.isBleSupported()) {
            System.println("Manual-only blood sugar app mode");
            return;
        }

        _profileManager = new ProfileManager();
        _bleDelegate = new BloodSugarServiceBleDelegate(
            _profileManager as ProfileManager
        );
        _deviceManager = new DeviceManager(
            _bleDelegate as BloodSugarServiceBleDelegate,
            _profileManager as ProfileManager
        );

        BluetoothLowEnergy.setDelegate(
            _bleDelegate as BloodSugarServiceBleDelegate
        );

        (_profileManager as ProfileManager).registerProfiles();
    }

    function onInactive(state as Dictionary?) as Void {}

    function onStop(state as Dictionary?) as Void {
        if (BloodSugarStore.isBleSupported()) {
            try {
                BluetoothLowEnergy.setScanState(
                    BluetoothLowEnergy.SCAN_STATE_OFF
                );
            } catch (error) {
                System.println("Could not stop BLE scan: " + error.toString());
            }
        }

        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if (!BloodSugarStore.getSetupDone()) {
            var setupView = new BloodSugarSetupView();
            var setupDelegate = new BloodSugarSetupDelegate(setupView);
            return [setupView, setupDelegate];
        }

        var homeView = new BloodSugarHomeView();
        var homeDelegate = new BloodSugarHomeDelegate(homeView);
        return [homeView, homeDelegate];
    }

    public function getBleDelegate() as BloodSugarServiceBleDelegate? {
        return _bleDelegate;
    }

    public function getDeviceManager() as DeviceManager? {
        return _deviceManager;
    }
}
