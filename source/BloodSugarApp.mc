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
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class BloodSugarApp extends Application.AppBase {
    private var _profileManager as ProfileManager?;
    private var _bleDelegate as BloodSugarServiceBleDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        BloodSugarStore.load();

        if (!BloodSugarStore.isBleSupported()) {
            return;
        }

        _profileManager = new ProfileManager();
        _bleDelegate = new BloodSugarServiceBleDelegate(
            _profileManager as ProfileManager
        );

        _deviceManager = new DeviceManager(
            _bleDelegate as BloodSugarServiceBleDelegate,
            _profileManager as ProfileManager
        );

        BluetoothLowEnergy.setDelegate(
            _bleDelegate as BloodSugarServiceBleDelegate
        );

        (_profileManager as ProfileManager).registerProfiles();

        if (BloodSugarStore.getBloodMonitor() == 0) {
            AbbottFreeStylePollingManager.start();
        }
    }

    function onInactive(state as Dictionary?) as Void {}

    function onStop(state as Dictionary?) as Void {
        if (BloodSugarStore.isBleSupported()) {
            try {
                BluetoothLowEnergy.setScanState(
                    BluetoothLowEnergy.SCAN_STATE_OFF
                );
            } catch (error) {
                System.println("Could not stop BLE scan: " + error.toString());
            }
        }

        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        if (!BloodSugarStore.getSetupDone()) {
            var setupView = new BloodSugarSetupUnitView();
            var setupDelegate = new BloodSugarSetupUnitDelegate(setupView);
            return [setupView, setupDelegate];
        }

        var homeView = new BloodSugarHomeView();
        var homeDelegate = new BloodSugarHomeDelegate(homeView);
        return [homeView, homeDelegate];
    }

    public function getBleDelegate() as BloodSugarServiceBleDelegate? {
        return _bleDelegate;
    }

    public function getDeviceManager() as DeviceManager? {
        return _deviceManager;
    }
    public function onHide() as Void {
        AbbottFreeStylePollingManager.stop();
    }

    public function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BloodSugarBackgroundDelegate()];
    }
}
