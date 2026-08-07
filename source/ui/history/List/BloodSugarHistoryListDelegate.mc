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

import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarHistoryListDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarHistoryListView;
    private var _menuView = new Rez.Menus.MainMenu();
    private var _menuDelegate = new BloodSugarMenuDelegate();
    private var _select as Number;
    private var times;

    public function initialize(view as BloodSugarHistoryListView) {
        BehaviorDelegate.initialize();
        _select = 1;
        _parentView = view;
        updateView();
    }

    public function updateView() as Void {
        var history = BloodSugarStore.getHistory();
        times = [];
        var values = [];
        var useMgdl = BloodSugarStore.getUseMgdl();

        for (var i = 0; i < history.size(); i++) {
            var reading = history[i];

            if (!(reading instanceof Array) || reading.size() < 2) {
                continue;
            }

            var valueMmol = reading[BloodSugarReading.VALUE_MMOL].toFloat();

            if (useMgdl) {
                values.add(BloodSugarStore.MollToMgdl(valueMmol));
            } else {
                values.add(valueMmol);
            }

            times.add(reading[BloodSugarReading.TIME]);
        }

        var zones = BloodSugarStore.getBloodSugarZones();
        var displayZones = [];

        for (var zoneIndex = 0; zoneIndex < zones.size(); zoneIndex++) {
            var zoneValue = zones[zoneIndex].toFloat();

            if (useMgdl) {
                displayZones.add(BloodSugarStore.MollToMgdl(zoneValue));
            } else {
                displayZones.add(zoneValue);
            }
        }

        _parentView.setBloodSugarHistory(
            values,
            times,
            displayZones,
            BloodSugarStore.getUnitText(useMgdl)
        );
    }

    public function updateSelect() as Void {
        _parentView.setBloodSugarSelect(_select);
    }

    public function editSelect(selectedTime) {
        var view = new BloodSugarView();
        var delegate = new BloodSugarDelegate(view, selectedTime);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
    }

    public function onBack() as Boolean {
        System.exit();
        return true;
    }

    public function onSelect() as Boolean {
        editSelect(times[_select - 1]);
        return true;
    }

    public function onMenu() as Boolean {
        WatchUi.pushView(_menuView, _menuDelegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onNextPage() as Boolean {
        _select++;
        if (_select > times.size()) {
            _select = times.size();
        }
        updateSelect();
        return true;
    }

    public function onPreviousPage() as Boolean {
        _select--;
        if (_select < 1) {
            _select = 1;
        }
        updateSelect();
        return true;
    }

    public function refresh() as Void {
        updateView();
    }
}
