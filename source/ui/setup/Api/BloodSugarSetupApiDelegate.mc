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
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiDelegate extends WatchUi.Menu2InputDelegate {
    const FIELD_USERNAME = 0;
    const FIELD_PASSWORD = 1;
    const FIELD_CONNECT = 2;
    const DEXCOM_REGION_US = 0;
    const DEXCOM_REGION_JP = 1;
    const DEXCOM_REGION_OUS = 2;
    const CONNECTED_DELAY_MS = 1500;

    private var _view as BloodSugarSetupApiView;
    private var _username as String;
    private var _password as String;
    private var _dexcomRegion as Number;
    private var _status as String;
    private var _busy as Boolean;
    private var _monitorId as Number;
    private var _navigationTimer as Timer.Timer?;

    private var _apiClient as AbbottFreeStyleApi or DexcomApi or Null;

    public function initialize(
        view as BloodSugarSetupApiView,
        monitorId as Number
    ) {
        Menu2InputDelegate.initialize();
        _view = view;
        _monitorId = monitorId;
        _username = BloodSugarApiStore.getUsername(_monitorId);
        _password = BloodSugarApiStore.getPassword(_monitorId);
        _dexcomRegion = DEXCOM_REGION_OUS;
        if (_monitorId == BloodSugarStore.MONITOR_DEXCOM) {
            var savedServer = BloodSugarApiStore.getServer(
                _monitorId,
                _username,
                DexcomApi.DEFAULT_SERVER
            );
            if (savedServer == DexcomApi.US_SERVER) {
                _dexcomRegion = DEXCOM_REGION_US;
            } else if (savedServer == DexcomApi.JP_SERVER) {
                _dexcomRegion = DEXCOM_REGION_JP;
            }
        }
        _status = "";
        _busy = false;
        _apiClient = null;
        _navigationTimer = null;
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
        if (id == :region) {
            openDexcomRegionPicker();
            return;
        }
        if (id == :connect) {
            connect();
        }
    }

    public function onBack() as Void {
        if (_busy) {
            if (
                _monitorId == BloodSugarStore.MONITOR_DEXCOM &&
                _apiClient instanceof DexcomApi
            ) {
                (_apiClient as DexcomApi).cancel();
                _apiClient = null;
                _busy = false;
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return;
            }

            _status = "Wait for the current request";
            updateView();
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    private function openKeyboard(field as Number) as Void {
        var isPasswordField = field == FIELD_PASSWORD;
        var title = isPasswordField ? "Password" : "Username";
        var initialText = isPasswordField ? _password : _username;
        var allowSpace = isPasswordField;
        if (!System.getDeviceSettings().isTouchScreen) {
            var picker = new BloodSugarCharacterPicker(
                initialText,
                title,
                96,
                allowSpace,
                false
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
            false,
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

    public function connect() as Void {
        if (_username.length() == 0) {
            _view.focusItem(FIELD_USERNAME);
            _status = "Enter your username";
            updateView();
            return;
        }

        if (_password.length() == 0) {
            _view.focusItem(FIELD_PASSWORD);
            _status = "Enter your password";
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
        var client = new DexcomApi(_username, _password, getDexcomServer());
        _apiClient = client;
        client.read(method(:onApiReadComplete));
    }

    private function openDexcomRegionPicker() as Void {
        var picker = new BloodSugarDexcomRegionPicker(getDexcomRegionIndex());
        WatchUi.pushView(
            picker,
            new BloodSugarDexcomRegionDelegate(self),
            WatchUi.SLIDE_UP
        );
    }

    public function setDexcomRegion(index as Number) as Void {
        _dexcomRegion =
            index >= DEXCOM_REGION_US && index <= DEXCOM_REGION_OUS
                ? index
                : DEXCOM_REGION_OUS;
        _status = "";
        updateView();
    }

    private function getDexcomRegionIndex() as Number {
        return _dexcomRegion;
    }

    private function getDexcomRegionName() as String {
        if (_dexcomRegion == DEXCOM_REGION_US) {
            return "United States";
        }
        if (_dexcomRegion == DEXCOM_REGION_JP) {
            return "Japan";
        }
        return "Everywhere else";
    }

    private function getDexcomServer() as String {
        if (_dexcomRegion == DEXCOM_REGION_US) {
            return DexcomApi.US_SERVER;
        }
        if (_dexcomRegion == DEXCOM_REGION_JP) {
            return DexcomApi.JP_SERVER;
        }
        return DexcomApi.OUS_SERVER;
    }

    private function startConnecting() as Void {
        _busy = true;
        _status = "Connecting to " + getProviderName() + "...";
        updateView();
    }

    public function onApiReadComplete(
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
        BloodSugarStore.invalidateHistoryCache();
        var saved = BloodSugarApiStore.saveCredentials(
            _monitorId,
            _username,
            _password
        );
        if (!saved) {
            _status = "Connected, but login was not saved";
            _apiClient = null;
            updateView();
            return;
        }

        BloodSugarStore.setSetupDone(true);
        (Application.getApp() as BloodSugarApp).updateBackgroundSync();
        _apiClient = null;
        showConnectedStatus(addedCount);
    }

    private function showConnectedStatus(addedCount as Number) as Void {
        _busy = true;
        if (addedCount > 0) {
            _status = getProviderName() + ": " + addedCount + " readings added";
        } else {
            _status = getProviderName() + " connected";
        }
        updateView();

        _navigationTimer = new Timer.Timer();
        (_navigationTimer as Timer.Timer).start(
            method(:onConnectedDelayElapsed),
            CONNECTED_DELAY_MS,
            false
        );
    }

    public function onConnectedDelayElapsed() as Void {
        _navigationTimer = null;
        _busy = false;
        showConnectedDestination();
    }

    private function showConnectedDestination() as Void {
        if (BloodSugarStore.getHistoryCount() > 0) {
            var historyView = new BloodSugarHistoryView();
            WatchUi.switchToView(
                historyView,
                new BloodSugarSetupHistoryDelegate(historyView),
                WatchUi.SLIDE_UP
            );
            return;
        }

        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }

    private function getShortError(errorMessage as String) as String {
        if (errorMessage.find("Bad credentials") != null) {
            return "Incorrect username or password";
        }

        if (errorMessage.find("Incorrect Dexcom") != null) {
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
        _view.setState(
            _username,
            _password,
            getDexcomRegionName(),
            _status,
            _busy
        );
    }
}

class BloodSugarSetupHistoryDelegate extends BloodSugarHistoryDelegate {
    public function initialize(view as BloodSugarHistoryView) {
        BloodSugarHistoryDelegate.initialize(view);
    }

    public function onBack() as Boolean {
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_LEFT
        );
        return true;
    }
}

class BloodSugarDexcomRegionDelegate extends WatchUi.PickerDelegate {
    private var _parent as BloodSugarSetupApiDelegate;

    public function initialize(parent as BloodSugarSetupApiDelegate) {
        PickerDelegate.initialize();
        _parent = parent;
    }

    public function onAccept(values as Array) as Boolean {
        var selected = values[0];
        if (!(selected instanceof Number)) {
            return false;
        }

        _parent.setDexcomRegion(selected as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
