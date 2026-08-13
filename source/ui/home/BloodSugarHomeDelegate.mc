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

class BloodSugarHomeDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarHomeView;

    public function initialize(view as BloodSugarHomeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onSelect() as Boolean {
        var view = new BloodSugarView();
        var delegate = new BloodSugarDelegate(view, null);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onPreviousPage() as Boolean {
        var view = new BloodSugarHistoryView();
        var delegate = new BloodSugarHistoryDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onMenu() as Boolean {
        var menu = new Rez.Menus.MainMenu();
        var delegate = new BloodSugarMenuDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        System.exit();
        return true;
    }
}
