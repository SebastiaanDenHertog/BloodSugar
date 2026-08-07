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

class BloodSugarSetupUnitView extends WatchUi.View {
    private var _useMgdl as Boolean;
    private var _useBloodMonitor as Number;

    private var _stage as Number;

    public function initialize() {
        View.initialize();
        _useMgdl = BloodSugarStore.getUseMgdl();
        _useBloodMonitor = 0;
        _stage = 0;
    }

    public function setEntry(
        useMgdl as Boolean,
        stage as Number,
        useBloodMonitor as Number
    ) as Void {
        _useMgdl = useMgdl;
        _stage = stage;
        _useBloodMonitor = useBloodMonitor;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, "Setup");

        if (_stage == 0) {
            dc.drawText(
                centerX,
                centerY - 35,
                Graphics.FONT_XTINY,
                "Choose your display unit",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_MEDIUM,
                BloodSugarStore.getUnitText(_useMgdl),
                Graphics.TEXT_JUSTIFY_CENTER
            );

            SafeText.drawBottomWithPadding(
                dc,
                "UP/DOWN change\nSELECT save",
                14
            );
        }
        if (_stage == 1) {
            dc.drawText(
                centerX,
                centerY - 70,
                Graphics.FONT_XTINY,
                "Do you want to connect\na blood monitor?",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_MEDIUM,
                BloodSugarStore.getBloodMonitorText(_useBloodMonitor),
                Graphics.TEXT_JUSTIFY_CENTER
            );

            SafeText.drawBottomWithPadding(
                dc,
                "UP/DOWN change\nSELECT save",
                14
            );
        }
    }
}
