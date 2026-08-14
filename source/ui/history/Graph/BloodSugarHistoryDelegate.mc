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

class BloodSugarHistoryDelegate extends WatchUi.BehaviorDelegate {
    const MAX_GRAPH_POINTS = 24;

    private var _parentView as BloodSugarHistoryView;
    private var _select as Number;
    private var _displayedCount as Number;

    public function initialize(view as BloodSugarHistoryView) {
        BehaviorDelegate.initialize();

        _parentView = view;
        _select = 0;
        _displayedCount = 0;
        updateView();
    }

    private function updateView() as Void {
        var times = [] as Array<Number>;
        var values = [] as Array<Float>;

        var count = BloodSugarStore.getHistoryCount();
        var useMgdl = BloodSugarStore.getUseMgdl();
        var startIndex = 0;

        if (count > MAX_GRAPH_POINTS) {
            startIndex = count - MAX_GRAPH_POINTS;
        }

        for (var index = startIndex; index < count; index++) {
            var timestamp = BloodSugarStore.getReadingTimeAt(index);

            var valueMmol = BloodSugarStore.getReadingValueMmolAt(index);

            if (timestamp == null || valueMmol == null) {
                continue;
            }

            var glucose = valueMmol as Float;

            if (glucose <= 0.0f) {
                continue;
            }

            if (useMgdl) {
                glucose = BloodSugarStore.MollToMgdl(glucose);
            }

            times.add(timestamp as Number);

            values.add(glucose);
        }

        _displayedCount = values.size();
        clampSelection();
        var dangerLow = BloodSugarStore.getDangerLowMmol();
        var low = BloodSugarStore.getLowMmol();
        var high = BloodSugarStore.getHighMmol();
        var dangerHigh = BloodSugarStore.getDangerHighMmol();

        if (useMgdl) {
            dangerLow = BloodSugarStore.MollToMgdl(dangerLow);
            low = BloodSugarStore.MollToMgdl(low);
            high = BloodSugarStore.MollToMgdl(high);
            dangerHigh = BloodSugarStore.MollToMgdl(dangerHigh);
        }

        var displayZones = [dangerLow, low, high, dangerHigh] as Array<Float>;

        _parentView.setBloodSugarHistory(
            values,
            times,
            displayZones,
            BloodSugarStore.getUnitText(useMgdl)
        );

        if (_displayedCount > 0) {
            updateSelect();
        }
    }

    private function clampSelection() as Void {
        if (_displayedCount <= 0) {
            _select = 0;
            return;
        }

        if (_select < 0) {
            _select = 0;
        }

        var lastIndex = _displayedCount - 1;

        if (_select > lastIndex) {
            _select = lastIndex;
        }
    }

    public function updateSelect() as Void {
        if (_displayedCount <= 0) {
            return;
        }

        clampSelection();

        _parentView.setBloodSugarSelect(_select);
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);

        return true;
    }

    public function onSelect() as Boolean {
        return false;
    }

    public function onMenu() as Boolean {
        var menu = new Rez.Menus.MainMenu();
        WatchUi.switchToView(
            menu,
            new BloodSugarMenuDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    public function onPreviousPage() as Boolean {
        if (_displayedCount <= 0) {
            return true;
        }

        _select++;
        clampSelection();
        updateSelect();
        return true;
    }

    public function onNextPage() as Boolean {
        if (_displayedCount <= 0) {
            return true;
        }

        _select--;
        clampSelection();
        updateSelect();

        return true;
    }

    public function refresh() as Void {
        updateView();
    }
}
