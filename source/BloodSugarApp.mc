import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {

    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize() {
        AppBase.initialize();
        Properties.setValue("diabeteMode", false);
    }

    function onStart(state as Dictionary?) as Void {
        _profileManager = new $.ProfileManager();
        _bleDelegate = new $.BloodSugarServiceDelegate(_profileManager as ProfileManager);
        _deviceManager = new $.DeviceManager(_bleDelegate as BloodSugarServiceDelegate, _profileManager as ProfileManager);
        
        BluetoothLowEnergy.setDelegate(_bleDelegate as BloodSugarServiceDelegate);
        (_profileManager as ProfileManager).registerProfiles();
        (_deviceManager as DeviceManager).start();
    }

    function onInactive(state as Dictionary or Null) as Void {
        if (Properties.getValue("diabeteMode")){
            _deviceManager = null;
            _bleDelegate = null;
            _profileManager = null;
        }

    }

    function onStop(state as Dictionary?) as Void {
        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    public function getInitialView() as [Views] or [Views, BloodSugarDelegate] {
        if (_deviceManager != null) {
            return [new $.BloodSugarView(_deviceManager)];
        }
        System.error("DeviceManager uninitialized.");
    }

}