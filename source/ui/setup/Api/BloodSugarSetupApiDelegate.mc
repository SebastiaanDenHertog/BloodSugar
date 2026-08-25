/*
MIT License

Copyright (c) 2026 Sebastiaan den Hertog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiDelegate extends WatchUi.Menu2InputDelegate {
    const FIELD_USERNAME = 0;
    const FIELD_PASSWORD = 1;
    const FIELD_CONNECT = 2;

    private var _view as BloodSugarSetupApiView;
    private var _username as String;
    private var _password as String;
    private var _status as String;
    private var _busy as Boolean;
    private var _monitorId as Number;

    private var _apiClient as AbbottFreeStyleApi or DexcomApi or Null;

    public function initialize(
        view as BloodSugarSetupApiView,
        monitorId as Number
    ) {
        Menu2InputDelegate.initialize();
        _view = view;
        _monitorId = monitorId;
        _username = BloodSugarStore.getUsername();
        _password = BloodSugarStore.getPassword();
        _status = "";
        _busy = false;
        _apiClient = null;
        updateView();
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        if (_busy) {
            return;
        }
        var id = item.getId();
        if (id == :username) {
            openKeyboard(FIELD_USERNAME);
            return;
        }
        if (id == :password) {
            openKeyboard(FIELD_PASSWORD);
            return;
        }
        if (id == :connect) {
            connect();
        }
    }

    public function onBack() as Void {
        if (_busy) {
            _status = "Wait for the current request";
            updateView();
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    private function openKeyboard(field as Number) as Void {
        var passwordMode = field == FIELD_PASSWORD;
        var title;
        if (_monitorId == BloodSugarStore.MONITOR_DEXCOM) {
            title = passwordMode ? "Client secret" : "Client ID";
        } else {
            title = passwordMode ? "Password" : "Username";
        }
        var initialText = passwordMode ? _password : _username;
        var allowSpace = passwordMode;
        if (!System.getDeviceSettings().isTouchScreen) {
            var picker = new BloodSugarCharacterPicker(
                initialText,
                title,
                96,
                allowSpace,
                passwordMode
            );
            WatchUi.pushView(
                picker,
                new BloodSugarCharacterPickerDelegate(picker, self, field),
                WatchUi.SLIDE_UP
            );
            return;
        }

        var keyboardView = new BloodSugarKeyboardView(
            initialText,
            passwordMode,
            title,
            96,
            allowSpace
        );
        var keyboardDelegate = new BloodSugarKeyboardDelegate(
            keyboardView,
            self,
            field
        );
        WatchUi.pushView(keyboardView, keyboardDelegate, WatchUi.SLIDE_UP);
    }

    public function handleKeyboardCompleted(
        field as Number,
        text as String
    ) as Void {
        if (field == FIELD_USERNAME) {
            _username = text;
        } else if (field == FIELD_PASSWORD) {
            _password = text;
        }
        _status = "";
        updateView();
    }

    public function handleKeyboardCancelled() as Void {
        _status = "Entry cancelled";
        updateView();
    }

    private function connect() as Void {
        if (_username.length() == 0) {
            _view.focusItem(FIELD_USERNAME);
            _status =
                _monitorId == BloodSugarStore.MONITOR_DEXCOM
                    ? "Enter your client ID"
                    : "Enter your username";
            updateView();
            return;
        }

        if (_password.length() == 0) {
            _view.focusItem(FIELD_PASSWORD);
            _status =
                _monitorId == BloodSugarStore.MONITOR_DEXCOM
                    ? "Enter your client secret"
                    : "Enter your password";
            updateView();
            return;
        }
        if (_monitorId == BloodSugarStore.MONITOR_ABBOTT) {
            startAbbottConnection();
            return;
        }
        if (_monitorId == BloodSugarStore.MONITOR_DEXCOM) {
            startDexcomConnection();
            return;
        }

        _status = "Unsupported account provider";
        updateView();
    }

    private function startAbbottConnection() as Void {
        startConnecting();
        var client = new AbbottFreeStyleApi(_username, _password);
        _apiClient = client;
        client.read(method(:onApiReadComplete));
    }

    private function startDexcomConnection() as Void {
        startConnecting();
        var client = new DexcomApi(_username, _password);
        _apiClient = client;
        client.read(method(:onApiReadComplete));
    }

    private function startConnecting() as Void {
        _busy = true;
        _status = "Connecting to " + getProviderName() + "...";
        updateView();
    }

    private function onApiReadComplete(
        success as Boolean,
        latestReadingTime as Number,
        latestValueMmol as Float,
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
            _apiClient = null;
            updateView();
            return;
        }

        BloodSugarStore.setSetupDone(true);
        (Application.getApp() as BloodSugarApp).updateBackgroundSync();
        if (addedCount > 0) {
            _status = getProviderName() + ": " + addedCount + " readings added";
        } else {
            _status = getProviderName() + " connected";
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

    private function getProviderName() as String {
        return BloodSugarStore.getBloodMonitorText(_monitorId);
    }

    private function updateView() as Void {
        _view.setState(_username, _password.length(), _status, _busy);
    }
}
