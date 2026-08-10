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

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarSetupUnitLayout(dc));
    }

    private function setLabel(id as String, value as String) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setText(value);
        }
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

        setLabel("unitTitle", "Setup");

        if (_stage == 0) {
            setLabel("unitPrompt", "Choose your display unit");

            setLabel("unitValue", BloodSugarStore.getUnitText(_useMgdl));
        } else {
            setLabel("unitPrompt", "Connect a blood monitor?");

            setLabel(
                "unitValue",
                BloodSugarStore.getBloodMonitorText(_useBloodMonitor)
            );
        }

        View.onUpdate(dc);

        SafeText.drawBottomWithPadding(dc, "UP/DOWN change\nSELECT save", 14);
    }
}
