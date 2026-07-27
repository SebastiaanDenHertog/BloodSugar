import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarHomeDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarHomeView;
    private var _menuView = new Rez.Menus.MainMenu();
    private var _menuDelegate = new BloodSugarMenuDelegate();

    public function initialize(view as BloodSugarHomeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onSelect() as Boolean {
        var view = new BloodSugarView();
        var delegate = new BloodSugarDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onPreviousPage() as Boolean {
        var view = new BloodSugarHistoryView();
        var delegate = new BloodSugarHistoryDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onNextPage() as Boolean {
        openSettings();
        return true;
    }

    public function onMenu() as Boolean {
        WatchUi.pushView(_menuView, _menuDelegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        System.exit();
        return true;
    }

    private function openSettings() as Void {}
}
