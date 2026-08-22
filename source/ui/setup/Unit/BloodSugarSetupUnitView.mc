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
import Toybox.Lang;

class BloodSugarSetupUnitView extends BloodSugarSelectionPicker {
    private const CHOICE_NONE = -1;
    private const CHOICE_NO = 0;
    private const CHOICE_YES = 1;

    private var _monitorChoice as Number;

    public function initialize() {
        _monitorChoice = CHOICE_NONE;
        var defaultIndex = BloodSugarStore.getUseMgdl() ? 1 : 0;
        BloodSugarSelectionPicker.initialize(
            "Choose your display unit",
            ["mmol/L", "mg/dL"],
            defaultIndex
        );
    }

    public function setMonitorChoice(connectMonitor as Boolean) as Void {
        _monitorChoice = connectMonitor ? CHOICE_YES : CHOICE_NO;
    }

    public function onShow() as Void {
        var choice = _monitorChoice;
        if (choice == CHOICE_NONE) {
            return;
        }
        _monitorChoice = CHOICE_NONE;

        if (choice == CHOICE_YES) {
            var monitorView = new BloodSugarSetupMonitorView();
            WatchUi.switchToView(
                monitorView,
                new BloodSugarSetupMonitorDelegate(monitorView),
                WatchUi.SLIDE_UP
            );
            return;
        }

        BloodSugarStore.setBloodMonitor(BloodSugarStore.MONITOR_NONE);
        BloodSugarStore.setSetupDone(true);
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }
}
