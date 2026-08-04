import Toybox.Application.Storage;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiDelegate extends WatchUi.BehaviorDelegate {
    const FIELD_USERNAME = 0;
    const FIELD_PASSWORD = 1;
    const FIELD_CONNECT = 2;
    const FIELD_COUNT = 3;

    private var _view as BloodSugarSetupApiView;
    private var _selected as Number;
    private var _username as String;
    private var _password as String;
    private var _status as String;
    private var _busy as Boolean;

    private var _apiClient as AbbottFreeStyleApi?;

    public function initialize(view as BloodSugarSetupApiView) {
        BehaviorDelegate.initialize();
        _view = view;
        _selected = FIELD_USERNAME;
        _username = BloodSugarStore.getUsername();
        _password = BloodSugarStore.getPassword();
        _status = "";
        _busy = false;
        _apiClient = null;
        updateView();
    }

    public function onPreviousPage() as Boolean {
        if (_busy) {
            return true;
        }

        _selected -= 1;

        if (_selected < 0) {
            _selected = FIELD_COUNT - 1;
        }

        _status = "";
        updateView();

        return true;
    }

    public function onNextPage() as Boolean {
        if (_busy) {
            return true;
        }

        _selected += 1;

        if (_selected >= FIELD_COUNT) {
            _selected = 0;
        }

        _status = "";
        updateView();

        return true;
    }

    public function onSelect() as Boolean {
        if (_busy) {
            return true;
        }

        if (_selected == FIELD_USERNAME) {
            openTextPicker(FIELD_USERNAME);

            return true;
        }

        if (_selected == FIELD_PASSWORD) {
            openTextPicker(FIELD_PASSWORD);

            return true;
        }

        if (_selected == FIELD_CONNECT) {
            connect();
            return true;
        }

        return false;
    }

    public function onBack() as Boolean {
        if (_busy) {
            _status = "Wait for the current request";

            updateView();
            return true;
        }

        WatchUi.popView(WatchUi.SLIDE_RIGHT);

        return true;
    }

    private function openTextPicker(field as Number) as Void {
        if (!(WatchUi has :TextPicker)) {
            _status = "Text entry is not supported";

            updateView();
            return;
        }

        var initialValue = "";

        if (field == FIELD_USERNAME) {
            initialValue = _username;
        }

        WatchUi.pushView(
            new WatchUi.TextPicker(initialValue),
            new BloodSugarSetupApiTextPickerDelegate(self, field),
            WatchUi.SLIDE_UP
        );
    }

    public function handleTextEntered(
        field as Number,
        text as String,
        changed as Boolean
    ) as Void {
        if (field == FIELD_USERNAME) {
            if (changed || _username.length() == 0) {
                _username = text;
            }
        } else if (field == FIELD_PASSWORD) {
            if (changed || _password.length() == 0) {
                _password = text;
            }
        }

        _status = "";
        updateView();
    }

    public function handleTextCancelled() as Void {
        _status = "Entry cancelled";
        updateView();
    }

    private function connect() as Void {
        if (_username.length() == 0) {
            _selected = FIELD_USERNAME;
            _status = "Enter your username first";

            updateView();
            return;
        }

        if (_password.length() == 0) {
            _selected = FIELD_PASSWORD;
            _status = "Enter your password first";

            updateView();
            return;
        }

        _busy = true;
        _status = "Connecting...";

        updateView();

        var client = new AbbottFreeStyleApi(_username, _password);

        _apiClient = client;

        client.read(method(:onApiReadComplete));
    }

    private function onApiReadComplete(
        success as Boolean,
        currentReading,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        _busy = false;

        if (!success) {
            _status = getShortError(errorMessage);

            _apiClient = null;

            updateView();
            return;
        }

        var saved = BloodSugarStore.saveUsernamePassword(_username, _password);

        if (!saved) {
            _status = "Connected, but login was not saved";

            updateView();
            return;
        }

        BloodSugarStore.setSetupDone(true);

        if (addedCount > 0) {
            _status = "Connected: " + addedCount + " readings added";
        } else {
            _status = "Connected successfully";
        }

        _apiClient = null;

        updateView();
    }

    private function getShortError(errorMessage as String) as String {
        if (errorMessage.find("Bad credentials") != null) {
            return "Incorrect username or password";
        }

        if (errorMessage.find("does not follow") != null) {
            return "Account follows no patient";
        }

        if (errorMessage.find("Additional account action") != null) {
            return "Open LibreLinkUp and finish setup";
        }

        if (errorMessage.length() == 0) {
            return "Could not connect";
        }

        return errorMessage;
    }

    private function updateView() as Void {
        _view.setState(
            _selected,
            _username,
            _password.length(),
            _status,
            _busy
        );
    }
}

class BloodSugarSetupApiTextPickerDelegate extends WatchUi.TextPickerDelegate {
    private var _parent as BloodSugarSetupApiDelegate;

    private var _field as Number;

    public function initialize(
        parent as BloodSugarSetupApiDelegate,
        field as Number
    ) {
        TextPickerDelegate.initialize();

        _parent = parent;
        _field = field;
    }

    public function onTextEntered(
        text as String,
        changed as Boolean
    ) as Boolean {
        _parent.handleTextEntered(_field, text, changed);

        return true;
    }

    public function onCancel() as Boolean {
        _parent.handleTextCancelled();

        return true;
    }
}
