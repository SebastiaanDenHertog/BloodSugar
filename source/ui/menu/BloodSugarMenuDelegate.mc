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

class BloodSugarMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var item = menuItem.getId();
        if (item == :newItem) {
            var view = new BloodSugarView();

            WatchUi.switchToView(
                view,
                new BloodSugarDelegate(view, null),
                WatchUi.SLIDE_RIGHT
            );

            return;
        }

        if (item == :settings) {
            var view = new BloodSugarSettingsView();

            WatchUi.switchToView(
                view,
                new BloodSugarSettingsDelegate(view),
                WatchUi.SLIDE_RIGHT
            );

            return;
        }

        if (item == :historyGraph) {
            var view = new BloodSugarHistoryView();

            WatchUi.switchToView(
                view,
                new BloodSugarHistoryDelegate(view),
                WatchUi.SLIDE_RIGHT
            );

            return;
        }

        if (item == :historyList) {
            var view = new BloodSugarHistoryListView();

            WatchUi.switchToView(
                view,
                new BloodSugarHistoryListDelegate(view),
                WatchUi.SLIDE_RIGHT
            );

            return;
        }

        if (item == :appInfo) {
            var view = new BloodSugarInfoView();

            WatchUi.switchToView(
                view,
                new BloodSugarInfoDelegate(view),
                WatchUi.SLIDE_RIGHT
            );

            return;
        }
    }
}
