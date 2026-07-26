import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BloodSugarSetupDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupView;
    private var _useMgdl as Boolean;

    public function initialize(view as BloodSugarSetupView) {
        BehaviorDelegate.initialize();
        _view = view;
        _useMgdl = BloodSugarStore.getUseMgdl();
        _view.setUseMgdl(_useMgdl);
    }

    public function onPreviousPage() as Boolean {
        _useMgdl = false;
        _view.setUseMgdl(_useMgdl);
        return true;
    }

    public function onNextPage() as Boolean {
        _useMgdl = true;
        _view.setUseMgdl(_useMgdl);
        return true;
    }

    public function onSelect() as Boolean {
        BloodSugarStore.setUseMgdl(_useMgdl);
        BloodSugarStore.setSetupDone(true);

        var homeView = new BloodSugarHomeView();
        var homeDelegate = new BloodSugarHomeDelegate(homeView);
        WatchUi.switchToView(homeView, homeDelegate, WatchUi.SLIDE_UP);
        return true;
    }
}
