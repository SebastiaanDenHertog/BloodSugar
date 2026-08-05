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

import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarModeDelegate extends WatchUi.BehaviorDelegate {
    private var _bleDelegate as BloodSugarServiceBleDelegate?;
    private var _deviceManager as DeviceManager?;

    public function initialize(
        bleDelegate as BloodSugarServiceBleDelegate?,
        deviceManager as DeviceManager?
    ) {
        BehaviorDelegate.initialize();
        _bleDelegate = bleDelegate;
        _deviceManager = deviceManager;
    }

    public function onSelect() as Boolean {
        if (!BloodSugarStore.isBleSupported()) {
            System.println("BLE setup is hidden before version 1.0.0");
            return true;
        }

        if (_bleDelegate == null || _deviceManager == null) {
            System.println("BLE setup is not ready");
            return true;
        }

        var view = new BloodSugarSetupBleView();
        var delegate = new BloodSugarSetupBleDelegate(
            _bleDelegate as BloodSugarServiceBleDelegate,
            _deviceManager as DeviceManager,
            view
        );

        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
