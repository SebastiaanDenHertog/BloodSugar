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

class BloodSugarKeyboardDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BloodSugarKeyboardView;
    private var _parent as BloodSugarSetupApiDelegate;
    private var _field as Number;

    public function initialize(
        view as BloodSugarKeyboardView,
        parent as BloodSugarSetupApiDelegate,
        field as Number
    ) {
        BehaviorDelegate.initialize();
        _view = view;
        _parent = parent;
        _field = field;
    }

    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var key = _view.getKeyAt(coordinates[0], coordinates[1]);
        if (key == null) {
            return false;
        }

        if (key.equals("SHIFT")) {
            _view.toggleUppercase();
            return true;
        }
        if (key.equals("PAGE")) {
            _view.togglePage();
            return true;
        }
        if (key.equals("DEL")) {
            _view.deleteLastCharacter();
            return true;
        }
        if (key.equals("CANCEL")) {
            closeCancelled();
            return true;
        }
        if (key.equals("DONE")) {
            closeCompleted();
            return true;
        }
        _view.appendKey(key);
        return true;
    }

    public function onBack() as Boolean {
        closeCancelled();
        return true;
    }

    private function closeCompleted() as Void {
        var text = _view.getText();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _parent.handleKeyboardCompleted(_field, text);
    }

    private function closeCancelled() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _parent.handleKeyboardCancelled();
    }
}
