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

    private function updateView() {
        var BloodSugarHistory = BloodSugarStore.getHistory();
        var time = [];
        var bloodsugar = [];
        var saveValues = BloodSugarStore.getSaveValues();
        for (var i = 0; i < BloodSugarHistory.size(); i++) {
            time.add(BloodSugarHistory[i][0]);
            bloodsugar.add(BloodSugarHistory[i][1]);
        }
        _parentView.setBloodSugarHistory(
                bloodsugar,
                time,
                saveValues
            );
        requestUpdate();
    }

    public function onPreviousPage() as Boolean {
        var view = new $.BloodSugarView();
        var delegate = new $.BloodSugarDelegate(view);
        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }

     public function onNextPage() as Boolean {
        var view = new $.BloodSugarView();
        var delegate = new $.BloodSugarDelegate(view);
        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_DOWN);
        return true;
    }
}