import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BloodSugarSetupUnitDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupUnitView;
    private var _useMgdl as Boolean;
    private var _useBloodMonitor as Boolean;
    private var _stage as Number;
    private var View as BloodSugarHomeView or BloodSugarSetupMonitorView;
    private var Delegate as
        BloodSugarHomeDelegate or BloodSugarSetupMonitorDelegate;

    public function initialize(view as BloodSugarSetupUnitView) {
        BehaviorDelegate.initialize();
        _view = view;
        _useMgdl = BloodSugarStore.getUseMgdl();
        _useBloodMonitor = BloodSugarStore.getUseBloodMonitor();
        _stage = 0;
        updateView();
    }

    public function onNextPage() as Boolean {
        if (_stage == 0) {
            _useMgdl = false;
            updateView();
            return true;
        }
        if (_stage == 1) {
            _useBloodMonitor = false;
            updateView();
            return true;
        }
    }

    public function onPreviousPage() as Boolean {
        if (_stage == 0) {
            _useMgdl = true;
            updateView();
            return true;
        }
        if (_stage == 1) {
            _useBloodMonitor = true;
            updateView();
            return true;
        }
    }

    public function onSelect() as Boolean {
        if (_stage == 0) {
            BloodSugarStore.setUseMgdl(_useMgdl);
            BloodSugarStore.setSetupDone(true);
            _stage = 1;
            updateView();
            return true;
        }
        if (_stage == 1) {
            BloodSugarStore.setUseBloodMonitor(_useBloodMonitor);
            if (_useBloodMonitor) {
                View = new BloodSugarSetupMonitorView();
                Delegate = new BloodSugarSetupMonitorDelegate(View);
            } else {
                View = new BloodSugarHomeView();
                Delegate = new BloodSugarHomeDelegate(View);
            }
        }

        WatchUi.switchToView(View, Delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        if (_stage == 0) {
            updateView();
            return true;
        }
        if (_stage == 1) {
            _stage = 0;
            updateView();
            return true;
        }
    }
    private function updateView() as Void {
        _view.setEntry(_useMgdl, _stage, _useBloodMonitor);
    }
}
