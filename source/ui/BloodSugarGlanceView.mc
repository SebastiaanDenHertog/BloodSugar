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

(:glance)
class BloodSugarGlanceView extends WatchUi.GlanceViewDelegate {
    public function initialize() {
        GlanceViewDelegate.initialize();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.clear();

        var storedReading = BloodSugarStore.getLatestReading();
        if (!(storedReading instanceof Array)) {
            drawNoData(dc);
            return;
        }

        var reading = storedReading as Array;

        if (reading.size() < 2) {
            drawNoData(dc);
            return;
        }

        if (
            !(reading[0] instanceof Number) ||
            !(reading[1] instanceof Number)
        ) {
            drawNoData(dc);
            return;
        }

        var timestamp = reading[0] as Number;
        var valueMmol = (reading[1] as Number).toFloat();
        var useMgdl = BloodSugarStore.getUseMgdl();
        var displayValue = BloodSugarStore.formatValue(valueMmol, useMgdl);
        var unit = BloodSugarStore.getUnitText(useMgdl);
        var status = getStatus(valueMmol);
        var ageText = getReadingAge(timestamp);

        dc.drawText(
            4,
            2,
            Graphics.FONT_XTINY,
            "Blood Sugar",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            4,
            height - 20,
            Graphics.FONT_XTINY,
            status,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            width - 4,
            1,
            Graphics.FONT_MEDIUM,
            displayValue,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
        dc.drawText(
            width - 4,
            height / 2,
            Graphics.FONT_XTINY,
            unit + " " + getTrendSymbol(),
            Graphics.TEXT_JUSTIFY_RIGHT
        );
        dc.drawText(
            width - 4,
            height - 18,
            Graphics.FONT_XTINY,
            ageText,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    private function drawNoData(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.drawText(
            4,
            2,
            Graphics.FONT_XTINY,
            "Blood Sugar",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            width - 4,
            height / 2 - dc.getFontHeight(Graphics.FONT_SMALL),
            Graphics.FONT_SMALL,
            "No data",
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    private function getStatus(valueMmol as Float) as String {
        if (valueMmol <= BloodSugarStore.getNotificationLowMmol()) {
            return "LOW";
        }
        if (valueMmol >= BloodSugarStore.getNotificationHighMmol()) {
            return "HIGH";
        }
        return "In Range";
    }

    private function getReadingAge(timestamp as Number) as String {
        var cuttentTimestamp = Time.now().value();
        var ageSeconds = cuttentTimestamp - timestamp;
        if (ageSeconds < 0) {
            ageSeconds = 0;
        }
        var ageMinutes = ageSeconds / 60;
        if (ageMinutes < 1) {
            return "Now";
        }
        if (ageMinutes < 60) {
            return ageMinutes + "m ago";
        }
        var ageHours = ageMinutes / 60;

        if (ageHours < 24) {
            return ageHours + "h age";
        }

        return "Old data";
    }

    private function getTrendSymbol() as String {
        // get last 5 masurements and get the avarage and return the trend with a arrow
        var useMgdl = BloodSugarStore.getUseMgdl();
        var readings = BloodSugarStore.getPartOfHistory(5);
        var avarage = 0.0 as Float;
        var BloodSugarAverage;
        for (var i = 0; i < readings.size(); i++) {
            avarage = +readings[i];
        }
        var displayValue = BloodSugarStore.formatValue(
            avarage,
            BloodSugarStore.getUseMgdl()
        ).toFloat();
        if (useMgdl) {
            BloodSugarAverage = 102;
        } else {
            BloodSugarAverage = 5.6;
        }
        if (displayValue == null) {
            return "?";
        }
        if (displayValue < BloodSugarAverage * 0.85) {
            return "↓";
        }
        if (displayValue < BloodSugarAverage * 0.9) {
            return "↘";
        }
        if (displayValue < BloodSugarAverage * 1.1) {
            return "↑";
        }
        if (displayValue < BloodSugarAverage * 1.5) {
            return "↗";
        }
        return "→";
    }
}
