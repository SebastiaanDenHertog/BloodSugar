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

class BloodSugarHistoryListDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarHistoryListView;
    private var _select as Number;
    private var _historyCount as Number;

    public function initialize(view as BloodSugarHistoryListView) {
        BehaviorDelegate.initialize();

        _parentView = view;
        _select = 0;
        _historyCount = 0;

        refresh();
    }

    public function updateView() as Void {
        _historyCount = BloodSugarStore.getHistoryCount();
        var useMgdl = BloodSugarStore.getUseMgdl();
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

        _parentView.setHistory(
            _historyCount,
            useMgdl,
            dangerLow,
            low,
            high,
            dangerHigh,
            BloodSugarStore.getUnitText(useMgdl)
        );

        if (_select > 0) {
            updateSelect();
        }
    }

    private function clampSelection() as Void {
        if (_historyCount == 0) {
            _select = 0;
            return;
        }

        if (_select < 1) {
            _select = 1;
        }

        if (_select > _historyCount) {
            _select = _historyCount;
        }
    }

    public function updateSelect() as Void {
        if (_historyCount == 0) {
            return;
        }

        clampSelection();

        _parentView.setBloodSugarSelect(_select);
    }

    public function editSelect(selectedTime) as Void {
        if (selectedTime == null) {
            return;
        }

        var view = new BloodSugarView();

        WatchUi.pushView(
            view,
            new BloodSugarDelegate(view, selectedTime),
            WatchUi.SLIDE_UP
        );
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_LEFT);

        return true;
    }

    public function onSelect() as Boolean {
        if (_historyCount == 0) {
            return true;
        }

        clampSelection();

        if (_select <= 0) {
            return true;
        }

        editSelect(BloodSugarStore.getReadingTimeAt(_select - 1));

        return true;
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

    public function onNextPage() as Boolean {
        if (_historyCount == 0) {
            return true;
        }

        _select++;

        if (_select > _historyCount) {
            _select = _historyCount;
        }

        updateSelect();

        return true;
    }

    public function onPreviousPage() as Boolean {
        if (_historyCount == 0) {
            return true;
        }

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
