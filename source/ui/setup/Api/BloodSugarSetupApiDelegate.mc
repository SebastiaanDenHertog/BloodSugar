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
            openKeyboard(FIELD_USERNAME);
            return true;
        }
        if (_selected == FIELD_PASSWORD) {
            openKeyboard(FIELD_PASSWORD);
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

    private function openKeyboard(field as Number) as Void {
        var passwordMode = field == FIELD_PASSWORD;
        var title = passwordMode ? "Password" : "Username";
        var initialText = passwordMode ? _password : _username;
        var allowSpace = passwordMode;
        var buttonMode = shouldUseButtonKeyboard();
        var keyboardView = new BloodSugarKeyboardView(
            initialText,
            passwordMode,
            title,
            96,
            allowSpace,
            buttonMode
        );
        var keyboardDelegate = new BloodSugarKeyboardDelegate(
            keyboardView,
            self,
            field
        );
        WatchUi.pushView(keyboardView, keyboardDelegate, WatchUi.SLIDE_UP);
    }

    private function shouldUseButtonKeyboard() as Boolean {
        var settings = System.getDeviceSettings();
        return !settings.isTouchScreen;
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
            _selected = FIELD_USERNAME;
            _status = "Enter your username";
            updateView();
            return;
        }

        if (_password.length() == 0) {
            _selected = FIELD_PASSWORD;
            _status = "Enter your password";
            updateView();
            return;
        }
        _busy = true;
        _status = "Connecting...";
        updateView();
        var client = new AbbottFreeStyleApi(_username, _password);
        _apiClient = client;
        client.read(self.onApiReadComplete);
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
            _apiClient = null;
            updateView();
            return;
        }

        BloodSugarStore.setSetupDone(true);
        (Application.getApp() as BloodSugarApp).updateBackgroundSync();
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
