import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarHistoryDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarHistoryView;

    public function initialize(view as BloodSugarHistoryView) {
        BehaviorDelegate.initialize();
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

        var targetLow = BloodSugarStore.getTargetLowMmol();
        var targetHigh = BloodSugarStore.getTargetHighMmol();

        if (useMgdl) {
            targetLow = BloodSugarStore.MollToMgdl(targetLow);
            targetHigh = BloodSugarStore.MollToMgdl(targetHigh);
        }

        _parentView.setBloodSugarHistory(
            values,
            times,
            targetLow,
            targetHigh,
            BloodSugarStore.getUnitText(useMgdl)
        );
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    public function onSelect() as Boolean {
        return onBack();
    }
}
