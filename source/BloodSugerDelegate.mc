import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new BloodSugerMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}