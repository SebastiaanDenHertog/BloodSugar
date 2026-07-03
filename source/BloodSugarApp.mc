import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {

    private var _profileManager as ProfileManager;
    private var _bleDelegate as BloodSugarServiceDelegate;

    public function initialize() {
        AppBase.initialize();

        _profileManager = new ProfileManager();

        _bleDelegate =
            new BloodSugarServiceDelegate(_profileManager);
    }

    function onStart(state as Dictionary?) as Void {
        BluetoothLowEnergy.setDelegate(_bleDelegate);

        _profileManager.registerProfiles();
    }

    function onInactive(state as Dictionary or Null) as Void {
        if (Properties.getValue("DiabeteMode")){

        }
    }

    function onStop(state as Dictionary?) as Void {
        BluetoothLowEnergy.setScanState(
            BluetoothLowEnergy.SCAN_STATE_OFF
        );

    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if(Properties.getValue("DiabeteMode")==null){
            return [new $.BloodSugarSetupView(), new $.BloodSugarSetupDelegate()];
        }

        var view = new BloodSugarView();
        var delegate = new BloodSugarDelegate(view);
        
        return [view,delegate];   
    }

}