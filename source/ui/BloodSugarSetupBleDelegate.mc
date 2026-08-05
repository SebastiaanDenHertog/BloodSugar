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

import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BloodSugarSetupBleDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupBleView;
    private var _deviceManager as DeviceManager;
    private var _scanResult as ScanResult?;

    public function initialize(
        bleDelegate as BloodSugarServiceBleDelegate,
        deviceManager as DeviceManager,
        view as BloodSugarSetupBleView
    ) {
        BehaviorDelegate.initialize();
        _deviceManager = deviceManager;
        _view = view;
        _scanResult = null;
        _deviceManager.notifyDeviceFound(self);
    }

    public function onSelect() as Boolean {
        _view.setDeviceName("");
        _view.setStatus("Searching...");
        _view.setIsScanning(true);
        _deviceManager.start();
        return true;
    }

    public function onBack() as Boolean {
        _deviceManager.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onDeviceFound(result as ScanResult) as Void {
        _scanResult = result;

        var name = result.getDeviceName();

        if (name == null || name.equals("")) {
            name = "Unnamed monitor";
        }

        _view.setIsScanning(false);
        _view.setDeviceName(name);
        _view.setStatus("Monitor found");

        var dialog = new WatchUi.Confirmation("Connect to " + name + "?");
        WatchUi.pushView(
            dialog,
            new BloodSugarBleConfirmationDelegate(self),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    public function handleConfirm(confirm as Boolean) as Void {
        if (confirm && _scanResult != null) {
            _view.setStatus("Connecting...");
            _deviceManager.connect(_scanResult as ScanResult);
        } else {
            _view.setStatus("Connection cancelled");
        }
    }
}

class BloodSugarBleConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var _parent as BloodSugarSetupBleDelegate;

    public function initialize(parent as BloodSugarSetupBleDelegate) {
        ConfirmationDelegate.initialize();
        _parent = parent;
    }

    public function onResponse(response as WatchUi.Confirm) as Boolean {
        _parent.handleConfirm(response == WatchUi.CONFIRM_YES);
        return true;
    }
}
