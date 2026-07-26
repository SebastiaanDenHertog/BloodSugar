import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;

class BloodSugarHistoryView extends WatchUi.View {
    const MAX_VISIBLE_POINTS = 24;

    private var _bloodSugar;
    private var _time;
    private var _targetLow as Float;
    private var _targetHigh as Float;
    private var _unit as String;

    public function initialize() {
        View.initialize();
        _bloodSugar = [];
        _time = [];
        _targetLow = 4.0f;
        _targetHigh = 10.0f;
        _unit = "mmol/L";
    }

    public function setBloodSugarHistory(
        bloodSugar,
        time,
        targetLow as Float,
        targetHigh as Float,
        unit as String
    ) as Void {
        _bloodSugar = bloodSugar;
        _time = time;
        _targetLow = targetLow;
        _targetHigh = targetHigh;
        _unit = unit;
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
            _bloodSugar.size() > 0 &&
            _bloodSugar.size() == _time.size()
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

        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 20,
            Graphics.FONT_XTINY,
            "SELECT or BACK to return",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawGraph(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var left = 34;
        var right = width - 18;
        var top = 48;
        var bottom = height - 48;
        var startIndex = 0;

        if (_bloodSugar.size() > MAX_VISIBLE_POINTS) {
            startIndex = _bloodSugar.size() - MAX_VISIBLE_POINTS;
        }

        var count = _bloodSugar.size() - startIndex;
        var minimum = _targetLow;
        var maximum = _targetHigh;

        for (var i = startIndex; i < _bloodSugar.size(); i++) {
            var value = _bloodSugar[i].toFloat();

            if (value < minimum) {
                minimum = value;
            }
            if (value > maximum) {
                maximum = value;
            }
        }

        var range = maximum - minimum;

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
        dc.drawLine(left, top, left, bottom);
        dc.drawLine(left, bottom, right, bottom);

        drawTargetLine(
            dc,
            left,
            right,
            top,
            bottom,
            minimum,
            maximum,
            _targetLow
        );
        drawTargetLine(
            dc,
            left,
            right,
            top,
            bottom,
            minimum,
            maximum,
            _targetHigh
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        var previousX = -1;
        var previousY = -1;

        for (var pointIndex = 0; pointIndex < count; pointIndex++) {
            var historyIndex = startIndex + pointIndex;
            var x;

            if (count == 1) {
                x = (left + right) / 2;
            } else {
                x = left + ((right - left) * pointIndex) / (count - 1);
            }

            var y = valueToY(
                _bloodSugar[historyIndex].toFloat(),
                top,
                bottom,
                minimum,
                maximum
            );

            if (previousX >= 0) {
                dc.drawLine(previousX, previousY, x, y);
            }

            dc.fillCircle(x, y, 2);
            previousX = x;
            previousY = y;
        }

        dc.drawText(
            2,
            top - 5,
            Graphics.FONT_XTINY,
            formatAxisValue(maximum),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            2,
            bottom - 8,
            Graphics.FONT_XTINY,
            formatAxisValue(minimum),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var latestValue = _bloodSugar[_bloodSugar.size() - 1].toFloat();
        dc.drawText(
            width / 2,
            height - 35,
            Graphics.FONT_XTINY,
            "Latest " + formatAxisValue(latestValue) + " " + _unit,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawTargetLine(
        dc as Graphics.Dc,
        left as Number,
        right as Number,
        top as Number,
        bottom as Number,
        minimum as Float,
        maximum as Float,
        target as Float
    ) as Void {
        var y = valueToY(target, top, bottom, minimum, maximum);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine(left, y, right, y);
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
}
