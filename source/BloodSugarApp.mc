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
import Toybox.Background;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {
    private const BACKGROUND_INTERVAL_SECONDS = 5 * 60;

    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarServiceBleDelegate?;
    private var _deviceManager as DeviceManager?;
    private var _abbottStarted = false;
    private var _bleStarted = false;

    public function initialize() {
        AppBase.initialize();
        _profileManager = null;
        _bleDelegate = null;
        _deviceManager = null;
    }

    public function onStart(state as Dictionary?) as Void {}

    public function onInactive(state as Dictionary?) as Void {}

    public function onStop(state as Dictionary?) as Void {
        if (_abbottStarted) {
            AbbottFreeStylePollingManager.stop();
        }
        if (_bleStarted) {
            stopBle();
        }
    }

    (:glance)
    public function getGlanceView() as
        [WatchUi.GlanceView] or
            [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or
            Null
    {
        if (!(WatchUi has :GlanceView)) {
            return null;
        }

        var view = new BloodSugarGlanceView();
        return [view];
    }

    public function getInitialView() as
        [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates]
    {
        if (!BloodSugarStore.getSetupDone()) {
            updateBackgroundPolling();
            var setupView = new BloodSugarSetupUnitView();
            var setupDelegate = new BloodSugarSetupUnitDelegate(setupView);
            return [setupView, setupDelegate];
        }

        updateBackgroundPolling();
        if (BloodSugarStore.getBloodMonitor() == BloodSugarStore.MONITOR_BLE) {
            initializeBle();
        }
        var view;
        var delegate;
        var bloodMonitorData = BloodSugarStore.load();
        if (bloodMonitorData.size() == 0) {
            view = new BloodSugarHomeView();
            delegate = new BloodSugarHomeDelegate(view);
        } else {
            view = new BloodSugarHistoryView();
            delegate = new BloodSugarHistoryDelegate(view);
        }
        return [view, delegate];
    }

    public function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BloodSugarBackgroundDelegate()];
    }

    public function updateBackgroundPolling() as Void {
        if (!(System has :ServiceDelegate)) {
            return;
        }
        var shouldPoll = shouldUseBackgroundPolling();
        var isRegistered = Background.getTemporalEventRegisteredTime() != null;
        if (shouldPoll && !isRegistered) {
            try {
                Background.registerForTemporalEvent(
                    new Time.Duration(BACKGROUND_INTERVAL_SECONDS)
                );
                System.println("Background glucose polling registered");
            } catch (error) {
                System.println(
                    "Could not register background polling: " + error.toString()
                );
            }

            return;
        }

        if (!shouldPoll && isRegistered) {
            try {
                Background.deleteTemporalEvent();
                System.println("Background glucose polling removed");
            } catch (error) {
                System.println(
                    "Could not remove background polling: " + error.toString()
                );
            }
        }
    }

    private function shouldUseBackgroundPolling() as Boolean {
        if (!BloodSugarStore.getSetupDone()) {
            return false;
        }

        if (
            BloodSugarStore.getBloodMonitor() != BloodSugarStore.MONITOR_ABBOTT
        ) {
            return false;
        }
        var username = BloodSugarStore.getUsername();
        var password = BloodSugarStore.getPassword();
        return username.length() > 0 && password.length() > 0;
    }

    private function initializeBle() as Void {
        if (!BloodSugarStore.isBleSupported()) {
            System.println("BLE is not supported");
            return;
        }

        if (
            _profileManager != null ||
            _bleDelegate != null ||
            _deviceManager != null
        ) {
            return;
        }

        var profileManager = new ProfileManager();
        var bleDelegate = new BloodSugarServiceBleDelegate(profileManager);
        var deviceManager = new DeviceManager(bleDelegate, profileManager);
        _profileManager = profileManager;
        _bleDelegate = bleDelegate;
        _deviceManager = deviceManager;
        BluetoothLowEnergy.setDelegate(bleDelegate);
        profileManager.registerProfiles();
    }

    private function stopBle() as Void {
        if (
            _profileManager == null &&
            _bleDelegate == null &&
            _deviceManager == null
        ) {
            return;
        }

        try {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
        } catch (error) {
            System.println("Could not stop BLE scan: " + error.toString());
        }

        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    public function getBleDelegate() as BloodSugarServiceBleDelegate? {
        return _bleDelegate;
    }

    public function getDeviceManager() as DeviceManager? {
        return _deviceManager;
    }
}
