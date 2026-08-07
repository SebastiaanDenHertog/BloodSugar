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
import Toybox.Time;

(:glance)
class BloodSugarGlanceView extends WatchUi.GlanceView {
    public function initialize() {
        GlanceView.initialize();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var leftWidth = width / 3;
        var leftCenterX = leftWidth / 2;
        var rightStartX = leftWidth;
        var rightWidth = width - rightStartX;
        var rightCenterX = rightStartX + rightWidth / 2;

        var titleY = 3;
        var valueY = height / 2 - 12;
        var statusY = valueY + dc.getFontHeight(Graphics.FONT_SMALL) + 2;

        var unitY = valueY + 3;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var storedReading = BloodSugarStore.getLatestReading();
        if (!(storedReading instanceof Array)) {
            drawNoData(dc);
            return;
        }

        var reading = storedReading as Array;
        if (reading.size() < 1) {
            drawNoData(dc);
            return;
        }

        if (
            !(reading[0] instanceof Number) &&
            (!(reading[1] instanceof Number) || !(reading[1] instanceof Float))
        ) {
            drawNoData(dc);
            return;
        }

        var timestamp = reading[0] as Number;
        var valueMmol = reading[1].toFloat();
        var useMgdl = BloodSugarStore.getUseMgdl();
        var displayValue = BloodSugarStore.formatValue(valueMmol, useMgdl);
        var unit = BloodSugarStore.getUnitText(useMgdl);
        var status = getStatus(valueMmol);
        var ageText = getReadingAge(timestamp);

        dc.drawText(
            leftCenterX,
            titleY,
            Graphics.FONT_XTINY,
            "Blood Sugar",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            leftCenterX,
            valueY,
            Graphics.FONT_SMALL,
            displayValue,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            leftCenterX,
            statusY,
            Graphics.FONT_XTINY,
            status,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        var unitX = rightCenterX - 8;

        dc.drawText(
            unitX,
            unitY,
            Graphics.FONT_XTINY,
            unit,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        drawTrendArrow(
            dc,
            unitX + 10,
            unitY + dc.getFontHeight(Graphics.FONT_XTINY) / 2,
            getTrend()
        );

        dc.drawText(
            rightCenterX,
            statusY,
            Graphics.FONT_XTINY,
            ageText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawNoData(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.drawText(
            width / 2,
            height / 2 - dc.getFontHeight(Graphics.FONT_TINY) / 2,
            Graphics.FONT_TINY,
            "No data",
            Graphics.TEXT_JUSTIFY_CENTER
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

    private function drawTrendArrow(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        trend as Number
    ) as Void {
        var size = 8;

        switch (trend) {
            case -2: // strong down
                dc.drawLine(x, y - size, x, y + size);
                dc.drawLine(x, y + size, x - 4, y + size - 5);
                dc.drawLine(x, y + size, x + 4, y + size - 5);
                break;

            case -1: // down-right
                dc.drawLine(x - size, y - size, x + size, y + size);
                dc.drawLine(x + size, y + size, x + size - 6, y + size);
                dc.drawLine(x + size, y + size, x + size, y + size - 6);
                break;

            case 0: // flat
                dc.drawLine(x - size, y, x + size, y);
                dc.drawLine(x + size, y, x + size - 5, y - 4);
                dc.drawLine(x + size, y, x + size - 5, y + 4);
                break;

            case 1: // up-right
                dc.drawLine(x - size, y + size, x + size, y - size);
                dc.drawLine(x + size, y - size, x + size - 6, y - size);
                dc.drawLine(x + size, y - size, x + size, y - size + 6);
                break;

            case 2: // strong up
                dc.drawLine(x, y + size, x, y - size);
                dc.drawLine(x, y - size, x - 4, y - size + 5);
                dc.drawLine(x, y - size, x + 4, y - size + 5);
                break;
        }
    }

    private function getTrend() as Number {
        var readings = BloodSugarStore.getPartOfHistory(5);

        if (readings == null || readings.size() == 0) {
            return 0;
        }

        var total = 0.0f;
        var count = 0;

        for (var i = 0; i < readings.size(); i++) {
            var reading = readings[i];

            if (!(reading instanceof Array)) {
                continue;
            }

            var record = reading as Array;

            if (
                record.size() <= BloodSugarReading.VALUE_MMOL ||
                record[BloodSugarReading.VALUE_MMOL] == null
            ) {
                continue;
            }

            total += record[BloodSugarReading.VALUE_MMOL].toFloat();
            count += 1;
        }

        if (count == 0) {
            return 0;
        }

        var average = total / count;

        // Temporary comparison until we make this a real trend calculation.
        var normalAverage = 5.6f;

        if (average < normalAverage * 0.85f) {
            return -2;
        }

        if (average < normalAverage * 0.90f) {
            return -1;
        }

        if (average <= normalAverage * 1.10f) {
            return 0;
        }

        if (average <= normalAverage * 1.50f) {
            return 1;
        }

        return 2;
    }
}
