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

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarGlanceLayout(dc));
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var storedReading = BloodSugarStore.getLatestReading();
        if (!(storedReading instanceof Array)) {
            setNoData();
            GlanceView.onUpdate(dc);
            return;
        }

        var reading = storedReading as Array;
        if (reading.size() <= BloodSugarReading.VALUE_MMOL) {
            setNoData();
            GlanceView.onUpdate(dc);
            return;
        }

        if (
            reading[BloodSugarReading.TIME] == null ||
            reading[BloodSugarReading.VALUE_MMOL] == null
        ) {
            setNoData();
            GlanceView.onUpdate(dc);
            return;
        }

        var timestamp = reading[BloodSugarReading.TIME].toNumber() as Number;
        var valueMmol =
            reading[BloodSugarReading.VALUE_MMOL].toFloat() as Float;
        var useMgdl = BloodSugarStore.getUseMgdl();
        var displayValue = BloodSugarStore.formatValue(valueMmol, useMgdl);
        var unit = BloodSugarStore.getUnitText(useMgdl);
        var status = getStatus(valueMmol);
        var ageText = getReadingAge(timestamp);

        setLabelText("GlanceValue", displayValue);
        setLabelText("GlanceUnit", unit);
        setLabelText("GlanceStatus", status);
        setLabelText("GlanceAge", ageText);
        GlanceView.onUpdate(dc);

        /*
         * Trend arrow is still custom drawn.
         *
         * 74% puts it just behind the unit.
         */
        var arrowX = (dc.getWidth() * 76) / 100;
        var arrowY = (dc.getHeight() * 48) / 100;
        drawTrendArrow(dc, arrowX, arrowY, getTrend());
    }

    private function setNoData() as Void {
        setLabelText("GlanceValue", "--");
        setLabelText("GlanceUnit", "");
        setLabelText("GlanceStatus", "No data");
        setLabelText("GlanceAge", "");
    }

    private function setLabelText(id as String, text as String) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setText(text);
        }
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

        return "Old";
    }

    private function drawTrendArrow(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        trend as Number
    ) as Void {
        var size = 5;
        var head = 3;

        switch (trend) {
            case -2:
                // ↓
                dc.drawLine(x, y - size, x, y + size);
                dc.drawLine(x, y + size, x - head, y + size - head);
                dc.drawLine(x, y + size, x + head, y + size - head);
                break;

            case -1:
                // ↘
                dc.drawLine(x - size, y - size, x + size, y + size);
                dc.drawLine(x + size, y + size, x + size - head, y + size);
                dc.drawLine(x + size, y + size, x + size, y + size - head);
                break;

            case 0:
                // →
                dc.drawLine(x - size, y, x + size, y);
                dc.drawLine(x + size, y, x + size - head, y - head);
                dc.drawLine(x + size, y, x + size - head, y + head);
                break;

            case 1:
                // ↗
                dc.drawLine(x - size, y + size, x + size, y - size);
                dc.drawLine(x + size, y - size, x + size - head, y - size);
                dc.drawLine(x + size, y - size, x + size, y - size + head);
                break;

            case 2:
                // ↑
                dc.drawLine(x, y + size, x, y - size);
                dc.drawLine(x, y - size, x - head, y - size + head);
                dc.drawLine(x, y - size, x + head, y - size + head);
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
