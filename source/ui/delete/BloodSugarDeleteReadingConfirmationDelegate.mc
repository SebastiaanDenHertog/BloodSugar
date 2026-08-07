import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarDeleteReadingConfirmationDelegate
    extends WatchUi.ConfirmationDelegate
{
    private var _parent as BloodSugarDelegate;
    private var _timestamp;

    public function initialize(parent as BloodSugarDelegate, timestamp) {
        ConfirmationDelegate.initialize();

        _parent = parent;
        _timestamp = timestamp;
    }

    public function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _parent.handleDeleteReading(_timestamp);
        }

        return true;
    }
}
