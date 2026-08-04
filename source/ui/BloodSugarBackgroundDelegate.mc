import Toybox.Background;
import Toybox.System;
import Toybox.Lang;

(:background)
class BloodSugarBackgroundDelegate extends System.ServiceDelegate {
    private var _client as AbbottFreeStyleApi?;

    public function initialize() {
        ServiceDelegate.initialize();

        _client = null;
    }

    public function onTemporalEvent() as Void {
        var username = BloodSugarStore.getUsername();

        var password = BloodSugarStore.getPassword();

        if (username.length() == 0 || password.length() == 0) {
            Background.exit(null);
            return;
        }

        var client = new AbbottFreeStyleApi(username, password);

        _client = client;

        client.read(method(:onReadComplete));
    }

    private function onReadComplete(
        success as Boolean,
        currentReading,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        _client = null;

        var result = {
            "success" => success,
            "addedCount" => addedCount,
            "errorMessage" => errorMessage,
        };

        Background.exit(result);
    }

    public function registerBloodSugarBackgroundPolling() as Void {
        Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    }
}
