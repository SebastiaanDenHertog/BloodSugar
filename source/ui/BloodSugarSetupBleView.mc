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

class BloodSugarSetupBleView extends WatchUi.View {
    private var _status as String = "Tap Search to Start";
    private var _deviceName as String = "";
    private var _isScanning as Boolean = false;

    public function initialize() {
        View.initialize();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var totalWidth = dc.getWidth();
        SafeText.drawTop(dc, "Setup");

        var y = 100;
        if (_isScanning) {
            _status = "Searching...";
        }
        dc.drawText(
            totalWidth / 2,
            y,
            Graphics.FONT_SMALL,
            _status,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += 50;

        if (_deviceName != null) {
            dc.drawText(
                totalWidth / 2,
                y,
                Graphics.FONT_SMALL,
                "Found:" + _deviceName,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function onHide() as Void {}

    public function setStatus(status as String) as Void {
        _status = status;
        WatchUi.requestUpdate();
    }

    public function setDeviceName(name as String) as Void {
        _deviceName = name;
        WatchUi.requestUpdate();
    }

    public function setIsScanning(scanning as Boolean) as Void {
        _isScanning = scanning;
        WatchUi.requestUpdate();
    }
}
