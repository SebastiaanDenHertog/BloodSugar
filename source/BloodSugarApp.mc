import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {

    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarServiceDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        _profileManager = new $.ProfileManager();
        _bleDelegate = new $.BloodSugarServiceDelegate(_profileManager);
        _deviceManager = new $.DeviceManager(_bleDelegate as BloodSugarServiceDelegate, _profileManager as ProfileManager);
        
        BluetoothLowEnergy.setDelegate(_bleDelegate as BloodSugarServiceDelegate);
        (_profileManager as ProfileManager).registerProfiles();
        (_deviceManager as DeviceManager).start();
    }

    function onInactive(state as Dictionary or Null) as Void {
        if (Properties.getValue("DiabeteMode")){
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

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if(Properties.getValue("DiabeteMode")==null){
            return [new $.BloodSugarSetupView(), new $.BloodSugarSetupDelegate()];
        }
        return [new $.BloodSugarView(), new $.BloodSugarDelegate(new $.BloodSugarView())];
        
    }

}