import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BloodSugarModeDelegate extends WatchUi.BehaviorDelegate {
    public function initialize() {}

    public function onMenu() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }

    private function handleConfirm(confirm as Boolean) as Void {}
}
