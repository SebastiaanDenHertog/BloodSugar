import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class BloodSugarMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        var view;
        var delegate;
        if (item == :settings) {
            view = new BloodSugarSettingsView();
            delegate = new BloodSugarSettingsDelegate(view);
        } else if (item == :historyGraph) {
            view = new BloodSugarHistoryView();
            delegate = new BloodSugarHistoryDelegate(view);
        } else if (item == :historyList) {
            view = new BloodSugarHistoryListView();
            delegate = new BloodSugarHistoryListDelegate(view);
        } else if (item == :appInfo) {
            view = new BloodSugarInfoView();
            delegate = new BloodSugarInfoDelegate(view);
        }
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
    }
}
