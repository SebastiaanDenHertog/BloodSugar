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

class BloodSugarSetupUnitDelegate extends WatchUi.PickerDelegate {
    private var _view as BloodSugarSetupUnitView;

    public function initialize(view as BloodSugarSetupUnitView) {
        PickerDelegate.initialize();
        _view = view;
    }

    public function onAccept(values as Array) as Boolean {
        var selected = values[0];
        if (!(selected instanceof Number)) {
            return false;
        }

        BloodSugarStore.setUseMgdl((selected as Number) == 1);
        var confirmation = new WatchUi.Confirmation("Connect a blood monitor?");
        WatchUi.pushView(
            confirmation,
            new BloodSugarMonitorConfirmationDelegate(_view),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    public function onBack() as Void {
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }

    public function onCancel() as Boolean {
        return true;
    }
}

class BloodSugarMonitorConfirmationDelegate
    extends WatchUi.ConfirmationDelegate
{
    private var _view as BloodSugarSetupUnitView;

    public function initialize(view as BloodSugarSetupUnitView) {
        ConfirmationDelegate.initialize();
        _view = view;
    }

    public function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _view.setMonitorChoice(true);
            return true;
        }

        if (response == WatchUi.CONFIRM_NO) {
            _view.setMonitorChoice(false);
        }
        return true;
    }

    public function onBack() as Void {
        var homeView = new BloodSugarHomeView();
        WatchUi.switchToView(
            homeView,
            new BloodSugarHomeDelegate(homeView),
            WatchUi.SLIDE_UP
        );
    }
}
