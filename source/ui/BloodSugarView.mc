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

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarView extends WatchUi.View {
    private var _bloodSugar as Float;
    private var _stage as Number;
    private var _useMgdl as Boolean;
    private var _context as String;
    private var _message as String;
    private var _isEditing as Boolean;
    private var _canDeleteReading as Boolean;

    public function initialize() {
        View.initialize();
        _bloodSugar = 5.5f;
        _stage = 0;
        _useMgdl = false;
        _context = "No context";
        _message = "";
        _isEditing = false;
        _canDeleteReading = false;
    }

    public function setEntry(
        bloodSugar as Float,
        stage as Number,
        useMgdl as Boolean,
        context as String,
        message as String,
        isEditing as Boolean,
        canDeleteReading as Boolean
    ) as Void {
        _bloodSugar = bloodSugar;
        _stage = stage;
        _useMgdl = useMgdl;
        _context = context;
        _message = message;
        _isEditing = isEditing;
        _canDeleteReading = canDeleteReading;

        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, getStageText());

        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_LARGE,
            formatValue(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 20,
            Graphics.FONT_XTINY,
            BloodSugarStore.getUnitText(_useMgdl),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_stage >= 1) {
            dc.drawText(
                centerX,
                centerY + 70,
                Graphics.FONT_XTINY,
                _context,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        var footer = getInstructionText();

        if (!_message.equals("")) {
            footer = _message;
        }

        SafeText.drawBottom(dc, footer);
    }

    private function formatValue() as String {
        if (_useMgdl) {
            return _bloodSugar.format("%.0f");
        }

        return _bloodSugar.format("%.1f");
    }

    private function getStageText() as String {
        if (_stage == 0) {
            if (_isEditing) {
                return "Edit measured value";
            }
            return "Set measured value";
        }
        if (_stage == 1) {
            if (_isEditing) {
                return "Edit context";
            }
            return "Measurement context";
        }
        if (_isEditing) {
            return "Confirm changes";
        }
        return "Confirm measurement";
    }

    private function getInstructionText() as String {
        if (_stage == 0) {
            if (_isEditing && _canDeleteReading) {
                return "UP/DOWN adjust\n" + "SELECT next / MENU delete";
            }
            return "UP/DOWN adjust\n" + "SELECT next";
        }

        if (_stage == 1) {
            if (_isEditing && _canDeleteReading) {
                return "UP/DOWN context\n" + "SELECT next / MENU delete";
            }
            return "UP/DOWN context\n" + "SELECT next";
        }

        if (_isEditing) {
            if (_canDeleteReading) {
                return "SELECT update\n" + "MENU delete / BACK edit";
            }
            return "SELECT update\n" + "BACK edit";
        }
        return "SELECT save\n" + "BACK edit";
    }
}
