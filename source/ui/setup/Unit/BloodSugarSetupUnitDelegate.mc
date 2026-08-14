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

class BloodSugarSetupUnitDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarSetupUnitView;
    private var _useMgdl as Boolean;
    private var _useBloodMonitor as Number;
    private var _stage as Number;

    public function initialize(view as BloodSugarSetupUnitView) {
        BehaviorDelegate.initialize();
        _view = view;
        _useMgdl = BloodSugarStore.getUseMgdl();
        _useBloodMonitor = BloodSugarStore.getBloodMonitor();
        _stage = 0;
        updateView();
    }

    public function onNextPage() as Boolean {
        if (_stage == 0) {
            _useMgdl = false;
            updateView();
            return true;
        }
        if (_stage == 1) {
            _useBloodMonitor = 0;
            updateView();
            return true;
        }

        return false;
    }

    public function onPreviousPage() as Boolean {
        if (_stage == 0) {
            _useMgdl = true;
            updateView();
            return true;
        }
        if (_stage == 1) {
            _useBloodMonitor = 1;
            updateView();
            return true;
        }

        return false;
    }

    public function onSelect() as Boolean {
        if (_stage == 0) {
            BloodSugarStore.setUseMgdl(_useMgdl);
            _stage = 1;
            updateView();
            return true;
        }

        if (_stage != 1) {
            return false;
        }

        if (_useBloodMonitor > 0) {
            var monitorView = new BloodSugarSetupMonitorView();
            WatchUi.switchToView(
                monitorView,
                new BloodSugarSetupMonitorDelegate(monitorView),
                WatchUi.SLIDE_UP
            );
            return true;
        }

        BloodSugarStore.setBloodMonitor(BloodSugarStore.MONITOR_NONE);
        BloodSugarStore.setSetupDone(true);
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    public function onBack() as Boolean {
        if (_stage == 0) {
            updateView();
            return true;
        }
        if (_stage == 1) {
            _stage = 0;
            updateView();
            return true;
        }

        return false;
    }
    private function updateView() as Void {
        _view.setEntry(_useMgdl, _stage, _useBloodMonitor);
    }
}
