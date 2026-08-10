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
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiView extends WatchUi.View {
    private var _selected as Number;
    private var _username as String;
    private var _passwordLength as Number;
    private var _status as String;
    private var _busy as Boolean;

    public function initialize() {
        View.initialize();

        _selected = 0;
        _username = "";
        _passwordLength = 0;
        _status = "";
        _busy = false;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarSetupApiLayout(dc));
    }

    public function setState(
        selected as Number,
        username as String,
        passwordLength as Number,
        status as String,
        busy as Boolean
    ) as Void {
        _selected = selected;
        _username = username;
        _passwordLength = passwordLength;
        _status = status;
        _busy = busy;

        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        var fieldWidth = (width * 70) / 100;
        var fieldHeight = (height * 11) / 100;

        if (fieldHeight < 30) {
            fieldHeight = 30;
        }

        drawFieldBackground(
            dc,
            centerX,
            (height * 20) / 100,
            fieldWidth,
            fieldHeight,
            _selected == 0
        );

        drawFieldBackground(
            dc,
            centerX,
            (height * 40) / 100,
            fieldWidth,
            fieldHeight,
            _selected == 1
        );

        drawFieldBackground(
            dc,
            centerX,
            (height * 60) / 100,
            fieldWidth,
            fieldHeight,
            _selected == 2
        );

        setLabel("apiTitle", "Account credentials", Graphics.COLOR_WHITE);
        setLabel(
            "apiUsername",
            shorten(getUsernameDisplay(), 24),
            _selected == 0 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE
        );
        setLabel(
            "apiPassword",
            getPasswordDisplay(),
            _selected == 1 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE
        );
        setLabel(
            "apiConnect",
            _busy ? "CONNECTING..." : "CONNECT",
            _selected == 2 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE
        );
        setLabel("apiStatus", _status, Graphics.COLOR_WHITE);
        View.onUpdate(dc);
        SafeText.drawBottom(dc, "UP/DOWN choose");
    }

    private function drawFieldBackground(
        dc as Graphics.Dc,
        centerX as Number,
        y as Number,
        width as Number,
        height as Number,
        selected as Boolean
    ) as Void {
        var x = centerX - width / 2;

        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillRectangle(x, y, width, height);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawRectangle(x, y, width, height);
        }
    }

    private function setLabel(
        id as String,
        value as String,
        color as Number
    ) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            var text = drawable as WatchUi.Text;

            text.setText(value);
            text.setColor(color);
        }
    }

    private function getUsernameDisplay() as String {
        if (_username.length() == 0) {
            return "Enter username";
        }

        return _username;
    }

    private function getPasswordDisplay() as String {
        if (_passwordLength == 0) {
            return "Enter password";
        }

        var visibleLength = _passwordLength;
        var masked = "";

        if (visibleLength > 16) {
            visibleLength = 16;
        }

        for (var index = 0; index < visibleLength; index++) {
            masked += "*";
        }

        if (_passwordLength > visibleLength) {
            masked += "+";
        }

        return masked;
    }

    private function shorten(
        value as String,
        maximumLength as Number
    ) as String {
        if (value.length() <= maximumLength) {
            return value;
        }

        return value.substring(0, maximumLength - 3) + "...";
    }
}
