import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarHistoryDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarHistoryView;
    private var _menuView = new Rez.Menus.MainMenu();
    private var _menuDelegate = new BloodSugarMenuDelegate();
    private var _select as Number;

    public function initialize(view as BloodSugarHistoryView) {
        BehaviorDelegate.initialize();
        _select = 0;
        _parentView = view;
        updateView();
    }

    private function updateView() as Void {
        var history = BloodSugarStore.getHistory();
        var times = [];
        var values = [];
        var useMgdl = BloodSugarStore.getUseMgdl();

        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (!(reading instanceof Array) || reading.size() < 2) {
                continue;
            }

            var valueMmol =
                reading[BloodSugarStore.READING_VALUE_MMOL].toFloat();

            if (useMgdl) {
                values.add(BloodSugarStore.MollToMgdl(valueMmol));
            } else {
                values.add(valueMmol);
            }

            times.add(reading[BloodSugarStore.READING_TIME]);
        }

        var zones = BloodSugarStore.getBloodSugarZones();
        var displayZones = [];

        for (var zoneIndex = 0; zoneIndex < zones.size(); zoneIndex++) {
            var zoneValue = zones[zoneIndex].toFloat();

            if (useMgdl) {
                displayZones.add(BloodSugarStore.MollToMgdl(zoneValue));
            } else {
                displayZones.add(zoneValue);
            }
        }

        _parentView.setBloodSugarHistory(
            values,
            times,
            displayZones,
            BloodSugarStore.getUnitText(useMgdl)
        );
    }

    public function updateSelect() as Void {
        _parentView.setBloodSugarSelect(_select);
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    public function onSelect() as Boolean {
        return onBack();
    }

    public function onMenu() as Boolean {
        WatchUi.pushView(_menuView, _menuDelegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onPreviousPage() as Boolean {
        _select++;
        updateSelect();
        return true;
    }

    public function onNextPage() as Boolean {
        _select--;
        if (_select < 0) {
            _select = 0;
        }
        updateSelect();
        return true;
    }
}
