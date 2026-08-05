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
import Toybox.System;
import Toybox.WatchUi;

class BloodSugarMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        var view;
        var delegate;
        if (item == :settings) {
            view = new BloodSugarSettingsView();
            delegate = new BloodSugarSettingsDelegate(view);
        } else if (item == :historyGraph) {
            view = new BloodSugarHistoryView();
            delegate = new BloodSugarHistoryDelegate(view);
        } else if (item == :historyList) {
            view = new BloodSugarHistoryListView();
            delegate = new BloodSugarHistoryListDelegate(view);
        } else if (item == :appInfo) {
            view = new BloodSugarInfoView();
            delegate = new BloodSugarInfoDelegate(view);
        }
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
    }
}
