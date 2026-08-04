import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class BloodSugarSetupMonitorDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupMonitorView;
    private var _select as Number;
    private var _bloodMonitors as Array<String>;
    private var view as BloodSugarSetupBleView or BloodSugarSetupApiView;
    private var delegate as
        BloodSugarSetupBleDelegate or BloodSugarSetupApiDelegate;

    public function initialize(view as BloodSugarSetupMonitorView) {
        BehaviorDelegate.initialize();
        _view = view;
        _select = 0;
        _bloodMonitors = BloodSugarStore.getBloodMonitors();
        updateView();
    }

    private function updateView() as Void {
        System.println(
            "_select: " + _select + " _bloodMonitors: " + _bloodMonitors
        );
        _view.setEntry(_select, _bloodMonitors);
    }

    public function onPreviousPage() as Boolean {
        if (_bloodMonitors.size() == 0) {
            return false;
        }

        _select -= 1;

        if (_select < 0) {
            _select = _bloodMonitors.size() - 1;
        }

        updateView();
        return true;
    }

    public function onNextPage() as Boolean {
        if (_bloodMonitors.size() == 0) {
            return false;
        }

        _select += 1;

        if (_select >= _bloodMonitors.size()) {
            _select = 0;
        }

        updateView();
        return true;
    }

    // 0 = Abbott FreeStyle

    public function onSelect() as Boolean {
        BloodSugarStore.setBloodMonitor(_select);
        System.println(_bloodMonitors[_select]);
        if (_select == 0) {
            view = new BloodSugarSetupApiView();
            delegate = new BloodSugarSetupApiDelegate(view);
        } else {
            view = new BloodSugarSetupBleView();
            var profileManager = new ProfileManager();
            var bleDelegate = new BloodSugarServiceBleDelegate(profileManager);
            var deviceManager = new DeviceManager(bleDelegate, profileManager);
            delegate = new BloodSugarSetupBleDelegate(
                bleDelegate as BloodSugarServiceBleDelegate,
                deviceManager as DeviceManager,
                view as BloodSugarSetupBleView
            );
        }
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
    }
}
