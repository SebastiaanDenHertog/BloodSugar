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
import Toybox.Application;
import Toybox.System;
import Toybox.Lang;

class BloodSugarSetupMonitorDelegate extends WatchUi.PickerDelegate {
    public function initialize(view as BloodSugarSetupMonitorView) {
        PickerDelegate.initialize();
    }

    public function onCancel() as Boolean {
        BloodSugarStore.setBloodMonitor(BloodSugarStore.MONITOR_NONE);
        BloodSugarStore.setSetupDone(true);
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }

    public function onBack() as Boolean {
        BloodSugarStore.setBloodMonitor(BloodSugarStore.MONITOR_NONE);
        BloodSugarStore.setSetupDone(true);
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }

    public function onAccept(values as Array) as Boolean {
        var selected = values[0];
        if (!(selected instanceof Number)) {
            return false;
        }

        var monitorId = BloodSugarStore.getBloodMonitorIdAt(selected as Number);
        if (monitorId == BloodSugarStore.MONITOR_NONE) {
            return false;
        }

        if (
            monitorId == BloodSugarStore.MONITOR_ABBOTT ||
            monitorId == BloodSugarStore.MONITOR_DEXCOM ||
            monitorId == BloodSugarStore.MONITOR_XDRIP
        ) {
            BloodSugarStore.setBloodMonitor(monitorId);
            var apiView = new BloodSugarSetupApiView(monitorId);
            WatchUi.pushView(
                apiView,
                new BloodSugarSetupApiDelegate(apiView, monitorId),
                WatchUi.SLIDE_LEFT
            );
            return true;
        }

        if (monitorId == BloodSugarStore.MONITOR_BLE) {
            var app = Application.getApp() as BloodSugarApp;
            app.initializeBle();
            var bleDelegate = app.getBleDelegate();
            var deviceManager = app.getDeviceManager();

            if (bleDelegate == null || deviceManager == null) {
                System.println("BLE setup is not available");
                return true;
            }

            BloodSugarStore.setBloodMonitor(monitorId);
            var bleView = new BloodSugarSetupBleView();
            WatchUi.pushView(
                bleView,
                new BloodSugarSetupBleDelegate(
                    bleDelegate as BloodSugarServiceBleDelegate,
                    deviceManager as DeviceManager,
                    bleView
                ),
                WatchUi.SLIDE_LEFT
            );
            return true;
        }

        return false;
    }
}
