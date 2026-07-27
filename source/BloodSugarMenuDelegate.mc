import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class BloodSugarMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :settings) {
            var view = new BloodSugarSettingsView();
            var delegate = new BloodSugarSettingsDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (item == :history) {
            var historyView = new BloodSugarHistoryView();
            var historyDelegate = new BloodSugarHistoryDelegate(historyView);
            WatchUi.pushView(historyView, historyDelegate, WatchUi.SLIDE_RIGHT);
        } else if (item == :appInfo) {
            var infoView = new BloodSugarInfoView();
            var infoDelegate = new BloodSugarInfoDelegate(infoView);
            WatchUi.pushView(infoView, infoDelegate, WatchUi.SLIDE_RIGHT);
        }
    }
}
