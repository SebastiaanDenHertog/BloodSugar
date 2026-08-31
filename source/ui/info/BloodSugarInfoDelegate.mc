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
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarInfoDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarInfoView;
    private var _message as String;

    public function initialize(view as BloodSugarInfoView) {
        BehaviorDelegate.initialize();
        _parentView = view;
        var versiontext =
            "App version  " + (BloodSugarStore.getAppVersion() as String);
        _message =
            "Blood Sugar logger" +
            "\n\n" +
            "MIT License.\nCopyright (c) 2026\nSebastiaan den Hertog" +
            "\n\n" +
            versiontext;

        updateView();
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function updateView() as Void {
        _parentView.setEntry(_message);
    }

    public function onMenu() as Boolean {
        var menu = new Rez.Menus.MainMenu();
        var delegate = new BloodSugarMenuDelegate();
        WatchUi.switchToView(menu, delegate, WatchUi.SLIDE_UP);
        return true;
    }
}
