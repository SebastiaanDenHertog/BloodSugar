
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupDelegate extends WatchUi.BehaviorDelegate {

    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onNextPage() as Boolean {
        WatchUi.switchToView(new $.BloodSugarView(), new $.BloodSugarDelegate(new $.BloodSugarView()), WatchUi.SLIDE_BLINK);
        return true;
    }

    public function onPreviousPage() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
}