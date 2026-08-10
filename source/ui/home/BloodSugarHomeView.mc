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
import Toybox.Time;
import Toybox.WatchUi;

class BloodSugarHomeView extends WatchUi.View {
    private var _reading;
    private var _useMgdl as Boolean;

    public function initialize() {
        View.initialize();
        _reading = null;
        _useMgdl = false;
    }

    public function onShow() as Void {
        refresh();
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarHomeLayout(dc));
    }

    public function refresh() as Void {
        _reading = BloodSugarStore.getLatestReading();
        _useMgdl = BloodSugarStore.getUseMgdl();
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        setLabel("homeTitle", "Blood sugar");

        if (_reading == null || _reading.size() < 2) {
            setLabel("homeValue", "");
            setLabel("homeUnit", "");
            setLabel("homeSubtitle", "");
            setLabel("homeNoReadings", "No readings");
        } else {
            var valueMmol = _reading[BloodSugarReading.VALUE_MMOL].toFloat();
            var valueText = BloodSugarStore.formatValue(valueMmol, _useMgdl);
            var unitText = BloodSugarStore.getUnitText(_useMgdl);

            setLabel("homeValue", valueText);
            setLabel("homeUnit", unitText);
            setLabel("homeSubtitle", getReadingSubtitle());
            setLabel("homeNoReadings", "");
        }

        View.onUpdate(dc);
        SafeText.drawBottom(dc, "SELECT add new \n UP history");
    }

    private function getReadingSubtitle() as String {
        if (_reading == null) {
            return "";
        }

        var timestamp = _reading[BloodSugarReading.TIME].toNumber();
        var elapsed = Time.now().value() - timestamp;
        var timeText;

        if (elapsed < 60) {
            timeText = "just now";
        } else if (elapsed < 3600) {
            timeText = (elapsed / 60).format("%d") + " min ago";
        } else if (elapsed < 86400) {
            timeText = (elapsed / 3600).format("%d") + " h ago";
        } else {
            timeText = (elapsed / 86400).format("%d") + " d ago";
        }

        var contextIndex = 0;

        if (_reading.size() > BloodSugarReading.CONTEXT) {
            contextIndex = BloodSugarStore.getContextIndex(
                _reading[BloodSugarReading.CONTEXT].toString()
            );
        }

        if (contextIndex == 0) {
            return timeText;
        }

        return timeText + " | " + BloodSugarStore.getContextLabel(contextIndex);
    }

    private function setLabel(id as String, value as String) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setText(value);
        }
    }
}
