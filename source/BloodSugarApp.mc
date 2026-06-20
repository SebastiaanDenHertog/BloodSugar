import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;
import Application.Properties;

class BloodSugarApp extends Application.AppBase {

    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize() {
        AppBase.initialize();
        Properties.setValue("diabeteMode", false);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        _profileManager = new $.ProfileManager();
        _bleDelegate = new $.BloodSugarServiceDelegate(_profileManager as ProfileManager);
        _deviceManager = new $.DeviceManager(_bleDelegate as BloodSugarServiceDelegate, _profileManager as ProfileManager);
        
        BluetoothLowEnergy.setDelegate(_bleDelegate as BloodSugarServiceDelegate);
        (_profileManager as ProfileManager).registerProfiles();
        (_deviceManager as DeviceManager).start();
    }

    // onStop() is called when your application is exiting
    function onInactive(state as Dictionary or Null) as Void {
        if (Properties.getValue("diabeteMode")){
            _deviceManager = null;
            _bleDelegate = null;
            _profileManager = null;
        }

    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    //! Return the initial view for the app
    //! @return Array [View]
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if (_deviceManager != null) {
            return [new $.BloodSugarView(_deviceManager)];
        }
        System.error("DeviceManager uninitialized.");
    }

}