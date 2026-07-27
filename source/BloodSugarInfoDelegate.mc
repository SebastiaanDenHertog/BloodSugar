import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarInfoDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarInfoView;
    private var _message as String;

    public function initialize(view as BloodSugarInfoView) {
        BehaviorDelegate.initialize();
        _parentView = view;
        var appName = BloodSugarStore.getAppName() as String;

        var Creator =
            "Created by \n" + (BloodSugarStore.getAppCreator() as String);
        var versiontext =
            "App version  " + (BloodSugarStore.getAppVersion() as String);

        _message = appName + "\n" + Creator + "\n\n" + versiontext;

        updateView();
    }

    public function onSelect() as Boolean {
        updateView();
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function updateView() as Void {
        _parentView.setEntry(_message);
    }
}
