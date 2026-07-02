import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarHistoryDelegate extends WatchUi.BehaviorDelegate {

    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onPreviousPage() as Boolean {
        WatchUi.switchToView(new $.BloodSugarView(), new $.BloodSugarDelegate(new $.BloodSugarView()), WatchUi.SLIDE_UP);
        return true;
    }
}