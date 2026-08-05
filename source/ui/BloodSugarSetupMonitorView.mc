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

class BloodSugarSetupMonitorView extends WatchUi.View {
    private var _select as Number;
    private var _bloodMonitors as Array<String>;
    function initialize() {
        View.initialize();
        _select = 0;
        _bloodMonitors = [];
    }

    public function setEntry(
        select as Number,
        bloodMonitors as Array<String>
    ) as Void {
        _bloodMonitors = bloodMonitors;
        _select = select;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, "Monitor");
        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_XTINY,
            "Choose your monitor",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        var monitorName = "No monitors available";

        if (
            _bloodMonitors.size() > 0 &&
            _select >= 0 &&
            _select < _bloodMonitors.size()
        ) {
            monitorName = _bloodMonitors[_select];
        }

        dc.drawText(
            centerX,
            centerY + 5,
            Graphics.FONT_MEDIUM,
            monitorName,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        SafeText.drawBottomWithPadding(
            dc,
            "SELECT to continue\nUP/DOWN change",
            12
        );
    }
}
