import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarKeyboardDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarKeyboardView;
    private var _parent as BloodSugarSetupApiDelegate;
    private var _field as Number;

    public function initialize(
        view as BloodSugarKeyboardView,
        parent as BloodSugarSetupApiDelegate,
        field as Number
    ) {
        BehaviorDelegate.initialize();
        _view = view;
        _parent = parent;
        _field = field;
    }

    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var key = _view.getKeyAt(coordinates[0], coordinates[1]);
        if (key == null) {
            return false;
        }

        if (key.equals("SHIFT")) {
            _view.toggleUppercase();
            return true;
        }
        if (key.equals("PAGE")) {
            _view.togglePage();
            return true;
        }
        if (key.equals("DEL")) {
            _view.deleteLastCharacter();
            return true;
        }
        if (key.equals("CANCEL")) {
            closeCancelled();
            return true;
        }
        if (key.equals("DONE")) {
            closeCompleted();
            return true;
        }
        _view.appendKey(key);
        return true;
    }

    public function onBack() as Boolean {
        closeCancelled();
        return true;
    }

    private function closeCompleted() as Void {
        var text = _view.getText();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _parent.handleKeyboardCompleted(_field, text);
    }

    private function closeCancelled() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _parent.handleKeyboardCancelled();
    }
}
