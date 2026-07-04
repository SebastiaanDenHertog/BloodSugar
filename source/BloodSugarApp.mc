import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {
    private var _profileManager as ProfileManager;
    private var _bleDelegate as BloodSugarServiceDelegate;
    private var _deviceManager as DeviceManager;

    public function initialize() {
        AppBase.initialize();

        _profileManager = new ProfileManager();

        _bleDelegate = new BloodSugarServiceDelegate(_profileManager);
        _deviceManager = new DeviceManager(_bleDelegate, _profileManager);
    }

    function onStart(state as Dictionary?) as Void {
        BluetoothLowEnergy.setDelegate(_bleDelegate);

        _profileManager.registerProfiles();
    }

    function onInactive(state as Dictionary?) as Void {
        if (Properties.getValue("DiabeteMode")) {
        }
    }

    function onStop(state as Dictionary?) as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if (BloodSugarStore.getSetupDone()) {
            if (!BloodSugarStore.getDiabeteMode()) {
                var view = new BloodSugarSetupView();
                var delegate = new BloodSugarSetupDelegate(
                    _bleDelegate,
                    _deviceManager
                );
                return [view, delegate];
            }

            var view = new BloodSugarView();
            var delegate = new BloodSugarDelegate(view);

            return [view, delegate];
        } else {
            var view = new BloodSugarModeView();
            var delegate = new BloodSugarModeDelegate();

            return [view, delegate];
        }
    }
}
