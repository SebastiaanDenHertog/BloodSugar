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
import Toybox.Math;

class BloodSugarHistoryView extends WatchUi.View {
    const MAX_VISIBLE_POINTS = 24;

    const ZONE_DANGER_LOW = 0;
    const ZONE_LOW = 1;
    const ZONE_HIGH = 2;
    const ZONE_DANGER_HIGH = 3;

    private var _bloodSugar;
    private var _time;
    private var _zones;
    private var _unit as String;
    private var _selected as Number;

    private var _graphLeft as Number;
    private var _graphRight as Number;
    private var _graphTop as Number;
    private var _graphBottom as Number;
    private var _graphMinimum as Float;
    private var _graphMaximum as Float;

    public function initialize() {
        View.initialize();
        _bloodSugar = [];
        _time = [];
        _zones = [4.4f, 5.0f, 7.8f, 12.2f];
        _unit = "mmol/L";
        _graphLeft = 0;
        _graphRight = 0;
        _graphTop = 0;
        _graphBottom = 0;
        _graphMinimum = 0.0f;
        _graphMaximum = 1.0f;
        _selected = 0;
    }

    public function setBloodSugarHistory(
        bloodSugar,
        time,
        zones,
        unit as String
    ) as Void {
        _bloodSugar = bloodSugar;
        _time = time;
        _zones = zones;
        _unit = unit;
        WatchUi.requestUpdate();
    }

    public function setBloodSugarSelect(select as Number) as Void {
        _selected = select;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (!hasValidData()) {
            drawNoData(dc);
            return;
        }

        drawGraph(dc);
    }

    private function hasValidData() as Boolean {
        return (
            _bloodSugar != null &&
            _time != null &&
            _zones != null &&
            _bloodSugar.size() > 0 &&
            _bloodSugar.size() == _time.size() &&
            _zones.size() >= 4
        );
    }

    private function drawNoData(dc as Graphics.Dc) as Void {
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 - 20,
            Graphics.FONT_SMALL,
            "No history yet",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        SafeText.drawBottom(dc, "SELECT \n BACK to return");
    }

    private function drawGraph(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var left = (width * 0.15).toNumber();
        var right = (width - width * 0.15).toNumber();
        var top = (height * 0.15).toNumber();
        var bottom = (height - height * 0.15).toNumber();
        var startIndex = 0;

        if (_bloodSugar.size() > MAX_VISIBLE_POINTS) {
            startIndex = _bloodSugar.size() - MAX_VISIBLE_POINTS;
        }

        var count = _bloodSugar.size() - startIndex;

        var minimum = _zones[ZONE_DANGER_LOW].toFloat() as Float;
        var maximum = _zones[ZONE_DANGER_HIGH].toFloat() as Float;

        for (var i = startIndex; i < _bloodSugar.size(); i++) {
            var value = _bloodSugar[i].toFloat();

            if (value < minimum) {
                minimum = value;
            }
            if (value > maximum) {
                maximum = value;
            }
        }

        var range = (maximum as Float) - (minimum as Float);

        if (range < 1.0f) {
            range = 1.0f;
        }

        minimum -= range * 0.12f;
        maximum += range * 0.12f;

        if (minimum < 0.0f) {
            minimum = 0.0f;
        }

        dc.drawText(
            width / 2,
            10,
            Graphics.FONT_XTINY,
            "History (last " + count + ")",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        //dc.drawLine(left, top, left, bottom);
        //dc.drawLine(left, bottom, right, bottom);

        _graphLeft = left;
        _graphRight = right;
        _graphTop = top;
        _graphBottom = bottom;
        _graphMinimum = minimum;
        _graphMaximum = maximum;

        drawRangeLine(
            dc,
            _zones[ZONE_DANGER_LOW].toFloat(),
            _zones[ZONE_DANGER_LOW].format("%.2f"),
            true
        );
        drawRangeLine(
            dc,
            _zones[ZONE_LOW].toFloat(),
            _zones[ZONE_LOW].format("%.2f"),
            false
        );
        drawRangeLine(
            dc,
            _zones[ZONE_HIGH].toFloat(),
            _zones[ZONE_HIGH].format("%.2f"),
            false
        );
        drawRangeLine(
            dc,
            _zones[ZONE_DANGER_HIGH].toFloat(),
            _zones[ZONE_DANGER_HIGH].format("%.2f"),
            true
        );

        var previousX = -1;
        var previousY = -1;

        for (var pointIndex = 0; pointIndex < count; pointIndex++) {
            var historyIndex = startIndex + pointIndex;
            var pointValue = _bloodSugar[historyIndex].toFloat();
            var x;

            if (count == 1) {
                x = (left + right) / 2;
            } else {
                x = left + ((right - left) * pointIndex) / (count - 1);
            }

            var y = valueToY(pointValue, top, bottom, minimum, maximum);

            if (previousX >= 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(previousX, previousY, x, y);
            }

            dc.setColor(getPointColor(pointValue), Graphics.COLOR_BLACK);
            dc.fillCircle(x, y, 3);
            previousX = x;
            previousY = y;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        var lastIndex = _bloodSugar.size() - 1;

        var safeSelected = _selected;

        if (safeSelected < 0) {
            safeSelected = 0;
        } else if (safeSelected > lastIndex) {
            safeSelected = lastIndex;
        }

        var latestValue = _bloodSugar[lastIndex].toFloat();
        var latestValueSelected =
            _bloodSugar[lastIndex - safeSelected].toFloat();

        if (latestValue == latestValueSelected) {
            dc.drawText(
                width / 2,
                height - 35,
                Graphics.FONT_XTINY,
                "Latest " + formatAxisValue(latestValue) + " " + _unit,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            dc.drawText(
                width / 2,
                height - 35,
                Graphics.FONT_XTINY,
                formatAxisValue(latestValueSelected) + " " + _unit,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    private function drawRangeLine(
        dc as Graphics.Dc,
        target as Float,
        label as String,
        isDanger as Boolean
    ) as Void {
        var y = valueToY(
            target,
            _graphTop,
            _graphBottom,
            _graphMinimum,
            _graphMaximum
        );

        var lineColor = Graphics.COLOR_ORANGE;

        if (isDanger) {
            lineColor = Graphics.COLOR_RED;
        }

        dc.setColor(lineColor, Graphics.COLOR_BLACK);
        dc.drawLine(_graphLeft, y, _graphRight, y);
        if (label.equals(_zones[ZONE_DANGER_LOW].format("%.2f").toString())) {
            dc.drawText(
                _graphRight - 2,
                y - dc.getFontHeight(Graphics.FONT_XTINY) / 2,
                Graphics.FONT_XTINY,
                label,
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        } else {
            dc.drawText(
                _graphRight - 2,
                y - dc.getFontHeight(Graphics.FONT_XTINY),
                Graphics.FONT_XTINY,
                label,
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        }
    }

    private function getPointColor(value as Float) as Number {
        if (
            value < _zones[ZONE_DANGER_LOW].toFloat() ||
            value > _zones[ZONE_DANGER_HIGH].toFloat()
        ) {
            return Graphics.COLOR_RED;
        }

        if (
            value < _zones[ZONE_LOW].toFloat() ||
            value > _zones[ZONE_HIGH].toFloat()
        ) {
            return Graphics.COLOR_ORANGE;
        }

        return Graphics.COLOR_GREEN;
    }

    private function valueToY(
        value as Float,
        top as Number,
        bottom as Number,
        minimum as Float,
        maximum as Float
    ) as Number {
        var ratio = (value - minimum) / (maximum - minimum);
        return bottom - ((bottom - top).toFloat() * ratio).toNumber();
    }

    private function formatAxisValue(value as Float) as String {
        if (_unit.equals("mg/dL")) {
            return value.format("%.0f");
        }

        return value.format("%.1f");
    }

    public function onShow() as Void {
        var current = WatchUi.getCurrentView();

        if (
            current.size() > 1 &&
            current[1] instanceof BloodSugarHistoryDelegate
        ) {
            (current[1] as BloodSugarHistoryDelegate).refresh();
        }

        WatchUi.requestUpdate();
    }
}
