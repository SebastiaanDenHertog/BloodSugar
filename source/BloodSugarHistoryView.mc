import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;

class BloodSugarHistoryView extends WatchUi.View {

    private var _bloodSugar;
    private var _time;
    private var _saveValues;

    public function initialize() {
        View.initialize();

        _bloodSugar = [];
        _time = [];
        _saveValues = [];
    }

    public function setBloodSugarHistory(
        bloodSugar,
        time,
        saveValues
    ) as Void {
        _bloodSugar = bloodSugar;
        _time = time;
        _saveValues = saveValues;

        WatchUi.requestUpdate();
    }

    public function onUpdate(
        dc as Graphics.Dc
    ) as Void {
        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_BLACK
        );
        dc.clear();

        if (!hasValidData()) {
            drawNoData(dc);
            return;
        }

        drawHistoryGraph(dc);
    }

    private function hasValidData() as Boolean {
        if (_bloodSugar == null || _time == null) {
            return false;
        }

        if (_bloodSugar.size() == 0) {
            return false;
        }

        if (_bloodSugar.size() != _time.size()) {
            return false;
        }

        return true;
    }

    private function drawNoData(
        dc as Graphics.Dc
    ) as Void {
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_XTINY,
            "No blood sugar history",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawHistoryGraph(
        dc as Graphics.Dc
    ) as Void {
        var count = _bloodSugar.size();

        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        var font = Graphics.FONT_XTINY;
        var fontHeight = dc.getFontHeight(font);

        var shape =
            System.getDeviceSettings().screenShape;

        var minValue = getMinimumValue();
        var maxValue = getMaximumValue();

        if (maxValue == minValue) {
            minValue -= 1.0f;
            maxValue += 1.0f;
        } else {
            var valuePadding =
                (maxValue - minValue) * 0.10f;

            minValue -= valuePadding;
            maxValue += valuePadding;

            if (minValue < 0.0f) {
                minValue = 0.0f;
            }
        }

        var middleValue =
            minValue + ((maxValue - minValue) / 2.0f);

        /*
        * Scale spacing from the smaller screen dimension,
        * but keep sensible minimum and maximum sizes.
        */
        var gap = scaledSize(
            screenWidth,
            screenHeight,
            0.018f,
            3,
            9
        );

        var edgePadding = scaledSize(
            screenWidth,
            screenHeight,
            0.012f,
            2,
            7
        );

        var pointRadius = scaledSize(
            screenWidth,
            screenHeight,
            0.011f,
            2,
            4
        );

        var verticalInset;

        if (shape == System.SCREEN_SHAPE_ROUND) {
            verticalInset = scaledSize(
                screenWidth,
                screenHeight,
                0.060f,
                8,
                30
            );
        } else {
            verticalInset = scaledSize(
                screenWidth,
                screenHeight,
                0.030f,
                4,
                18
            );
        }

        var titleY = verticalInset;

        var timeLabelY =
            screenHeight
            - verticalInset
            - fontHeight;

        var graphTop =
            titleY + fontHeight + gap;

        var graphBottom =
            timeLabelY - gap;

        /*
        * Move the graph away from the narrow upper and lower
        * sections of a round screen. This generally gives a
        * wider and more readable graph.
        */
        if (shape == System.SCREEN_SHAPE_ROUND) {
            var preferredTop =
                (screenHeight.toFloat() * 0.18f).toNumber();

            var preferredBottom =
                (screenHeight.toFloat() * 0.82f).toNumber();

            if (graphTop < preferredTop) {
                graphTop = preferredTop;
            }

            if (graphBottom > preferredBottom) {
                graphBottom = preferredBottom;
            }
        }

        /*
        * Calculate safe horizontal boundaries at both the top
        * and bottom of the graph. On round screens the narrowest
        * of the two positions determines the usable width.
        */
        var topSafeLeft = getSafeLeft(
            screenWidth,
            screenHeight,
            graphTop,
            shape,
            edgePadding
        );

        var bottomSafeLeft = getSafeLeft(
            screenWidth,
            screenHeight,
            graphBottom,
            shape,
            edgePadding
        );

        var safeLeft = topSafeLeft;

        if (bottomSafeLeft > safeLeft) {
            safeLeft = bottomSafeLeft;
        }

        var topSafeRight = getSafeRight(
            screenWidth,
            screenHeight,
            graphTop,
            shape,
            edgePadding
        );

        var bottomSafeRight = getSafeRight(
            screenWidth,
            screenHeight,
            graphBottom,
            shape,
            edgePadding
        );

        var safeRight = topSafeRight;

        if (bottomSafeRight < safeRight) {
            safeRight = bottomSafeRight;
        }

        /*
        * Reserve only the width actually required by the
        * Y-axis values.
        */
        var valueLabelWidth =
            dc.getTextWidthInPixels(
                maxValue.format("%.1f"),
                font
            );

        var width = dc.getTextWidthInPixels(
            middleValue.format("%.1f"),
            font
        );

        if (width > valueLabelWidth) {
            valueLabelWidth = width;
        }

        width = dc.getTextWidthInPixels(
            minValue.format("%.1f"),
            font
        );

        if (width > valueLabelWidth) {
            valueLabelWidth = width;
        }

        var graphLeft =
            safeLeft + valueLabelWidth + gap;

        var graphRight = safeRight;

        var graphWidth =
            graphRight - graphLeft;

        var graphHeight =
            graphBottom - graphTop;

        /*
        * Use the full heading when it fits. Shorten it on
        * smaller round screens.
        */
        var title = "Blood Sugar History";

        var titleSafeLeft = getSafeLeft(
            screenWidth,
            screenHeight,
            titleY + (fontHeight / 2),
            shape,
            edgePadding
        );

        var titleSafeRight = getSafeRight(
            screenWidth,
            screenHeight,
            titleY + (fontHeight / 2),
            shape,
            edgePadding
        );

        if (
            dc.getTextWidthInPixels(title, font)
            > titleSafeRight - titleSafeLeft
        ) {
            title = "Blood Sugar";
        }

        drawHeader(
            dc,
            title,
            titleY,
            font
        );

        drawAxes(
            dc,
            graphLeft,
            graphRight,
            graphTop,
            graphBottom
        );

        drawValueLabels(
            dc,
            minValue,
            maxValue,
            graphLeft,
            graphTop,
            graphBottom,
            font
        );

        drawLines(
            dc,
            count,
            minValue,
            maxValue,
            graphLeft,
            graphTop,
            graphWidth,
            graphHeight,
            pointRadius
        );

        /*
        * Time labels sit lower than the graph, so calculate
        * their own safe round-screen boundaries.
        */
        var timeLeft = getSafeLeft(
            screenWidth,
            screenHeight,
            timeLabelY + (fontHeight / 2),
            shape,
            edgePadding
        );

        var timeRight = getSafeRight(
            screenWidth,
            screenHeight,
            timeLabelY + (fontHeight / 2),
            shape,
            edgePadding
        );

        drawTimeLabels(
            dc,
            timeLeft,
            timeRight,
            timeLabelY,
            font
        );
    }

    private function drawHeader(
        dc as Graphics.Dc,
        title as String,
        titleY as Number,
        font
    ) as Void {
        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            dc.getWidth() / 2,
            titleY,
            font,
            title,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawAxes(
        dc as Graphics.Dc,
        graphLeft as Number,
        graphRight as Number,
        graphTop as Number,
        graphBottom as Number
    ) as Void {
        dc.setColor(
            Graphics.COLOR_DK_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        // Y-axis.
        dc.drawLine(
            graphLeft,
            graphTop,
            graphLeft,
            graphBottom
        );

        // X-axis.
        dc.drawLine(
            graphLeft,
            graphBottom,
            graphRight,
            graphBottom
        );

        // Middle horizontal guide line.
        var middleY =
            graphTop + ((graphBottom - graphTop) / 2);

        dc.drawLine(
            graphLeft,
            middleY,
            graphRight,
            middleY
        );
    }

    private function drawValueLabels(
        dc as Graphics.Dc,
        minValue as Float,
        maxValue as Float,
        graphLeft as Number,
        graphTop as Number,
        graphBottom as Number,
        font
    ) as Void {
        var middleValue =
            minValue + ((maxValue - minValue) / 2.0f);

        var middleY =
            graphTop + ((graphBottom - graphTop) / 2);

        dc.setColor(
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            graphLeft - 4,
            graphTop,
            font,
            maxValue.format("%.1f"),
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        dc.drawText(
            graphLeft - 4,
            middleY,
            font,
            middleValue.format("%.1f"),
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        dc.drawText(
            graphLeft - 4,
            graphBottom,
            font,
            minValue.format("%.1f"),
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    private function drawLines(
        dc as Graphics.Dc,
        count as Number,
        minValue as Float,
        maxValue as Float,
        graphLeft as Number,
        graphTop as Number,
        graphWidth as Number,
        graphHeight as Number,
        pointRadius as Number
    ) as Void {
        if (count <= 0) {
            return;
        }

        dc.setColor(
            Graphics.COLOR_GREEN,
            Graphics.COLOR_TRANSPARENT
        );

        var valueRange = maxValue - minValue;

        // Safety against division by zero.
        if (valueRange <= 0.0f) {
            valueRange = 1.0f;
        }

        var firstTime = _time[0] as Number;
        var lastTime = _time[count - 1] as Number;
        var timeRange = lastTime - firstTime;

        // Calculate the first point separately.
        var firstValue = _bloodSugar[0].toFloat();

        var previousX = getPointX(
            0,
            count,
            firstTime,
            timeRange,
            graphLeft,
            graphWidth
        );

        var previousY = getPointY(
            firstValue,
            minValue,
            valueRange,
            graphTop,
            graphHeight
        );

        dc.fillCircle(
            previousX.toNumber(),
            previousY.toNumber(),
            pointRadius
        );

        // Start at the second point.
        for (var i = 1; i < count; i++) {
            var value = _bloodSugar[i].toFloat();

            var x = getPointX(
                i,
                count,
                firstTime,
                timeRange,
                graphLeft,
                graphWidth
            );

            var y = getPointY(
                value,
                minValue,
                valueRange,
                graphTop,
                graphHeight
            );

            dc.drawLine(
                previousX.toNumber(),
                previousY.toNumber(),
                x.toNumber(),
                y.toNumber()
            );

            dc.fillCircle(
                x.toNumber(),
                y.toNumber(),
                pointRadius
            );

            previousX = x;
            previousY = y;
        }
    }

    private function getPointX(
        index as Number,
        count as Number,
        firstTime as Number,
        timeRange as Number,
        graphLeft as Number,
        graphWidth as Number
    ) as Float {
        if (count == 1) {
            return (
                graphLeft + (graphWidth / 2.0f)
            ).toFloat();
        }

        if (timeRange > 0) {
            var currentTime = _time[index] as Number;

            var position =
                (currentTime - firstTime).toFloat()
                / timeRange.toFloat();

            return graphLeft.toFloat()
                + (position * graphWidth.toFloat());
        }

        // Fallback when timestamps are identical.
        var equalPosition =
            index.toFloat() / (count - 1).toFloat();

        return graphLeft.toFloat()
            + (equalPosition * graphWidth.toFloat());
    }

    private function getPointY(
        value as Float,
        minValue as Float,
        valueRange as Float,
        graphTop as Number,
        graphHeight as Number
    ) as Float {
        var normalizedValue =
            (value - minValue) / valueRange;

        return graphTop.toFloat()
            + graphHeight.toFloat()
            - (normalizedValue * graphHeight.toFloat());
    }

    private function drawTimeLabels(
        dc as Graphics.Dc,
        labelLeft as Number,
        labelRight as Number,
        labelY as Number,
        font
    ) as Void {
        var count = _time.size();

        var firstMoment =
            new Time.Moment(_time[0]);

        var lastMoment =
            new Time.Moment(_time[count - 1]);

        var firstLabel =
            formatMoment(firstMoment);

        var lastLabel =
            formatMoment(lastMoment);

        var requiredWidth =
            dc.getTextWidthInPixels(firstLabel, font)
            + dc.getTextWidthInPixels(lastLabel, font)
            + 6;

        var availableWidth =
            labelRight - labelLeft;

        /*
        * Use shorter labels when both complete timestamps
        * cannot fit.
        */
        if (requiredWidth > availableWidth) {
            if (isSameDate(firstMoment, lastMoment)) {
                firstLabel = formatTime(firstMoment);
                lastLabel = formatTime(lastMoment);
            } else {
                firstLabel = formatDate(firstMoment);
                lastLabel = formatDate(lastMoment);
            }
        }

        dc.setColor(
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            labelLeft,
            labelY,
            font,
            firstLabel,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            labelRight,
            labelY,
            font,
            lastLabel,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    private function isSameDate(
        firstMoment as Time.Moment,
        lastMoment as Time.Moment
    ) as Boolean {
        var first =
            Gregorian.info(
                firstMoment,
                Time.FORMAT_SHORT
            );

        var last =
            Gregorian.info(
                lastMoment,
                Time.FORMAT_SHORT
            );

        return first.year == last.year
            && first.month == last.month
            && first.day == last.day;
    }

    private function formatTime(
        moment as Time.Moment
    ) as String {
        var info =
            Gregorian.info(
                moment,
                Time.FORMAT_SHORT
            );

        return Lang.format(
            "$1$:$2$",
            [
                info.hour.format("%02d"),
                info.min.format("%02d")
            ]
        );
    }

    private function formatDate(
        moment as Time.Moment
    ) as String {
        var info =
            Gregorian.info(
                moment,
                Time.FORMAT_SHORT
            );

        return Lang.format(
            "$1$/$2$",
            [
                (info.month as Number).format("%02d"),
                info.day.format("%02d")
            ]
        );
    }

    private function formatMoment(
        moment as Time.Moment
    ) as String {
        var info =
            Gregorian.info(
                moment,
                Time.FORMAT_SHORT
            );

        return Lang.format(
            "$1$/$2$ $3$:$4$",
            [
                (info.month as Number).format("%02d"),
                info.day.format("%02d"),
                info.hour.format("%02d"),
                info.min.format("%02d")
            ]
        );
    }

    private function getMinimumValue() as Float {
        var minimum =
            _bloodSugar[0].toFloat();

        for (
            var i = 1;
            i < _bloodSugar.size();
            i++
        ) {
            var value =
                _bloodSugar[i].toFloat();

            if (value < minimum) {
                minimum = value;
            }
        }

        return minimum;
    }

    private function getMaximumValue() as Float {
        var maximum =
            _bloodSugar[0].toFloat();

        for (
            var i = 1;
            i < _bloodSugar.size();
            i++
        ) {
            var value =
                _bloodSugar[i].toFloat();

            if (value > maximum) {
                maximum = value;
            }
        }

        return maximum;
    }

    private function scaledSize(
        width as Number,
        height as Number,
        ratio as Float,
        minimum as Number,
        maximum as Number
    ) as Number {
        var smallest = width;

        if (height < smallest) {
            smallest = height;
        }

        var result =
            (smallest.toFloat() * ratio).toNumber();

        if (result < minimum) {
            return minimum;
        }

        if (result > maximum) {
            return maximum;
        }

        return result;
    }

    private function getRoundHalfWidth(
        width as Number,
        height as Number,
        y as Number
    ) as Float {
        var smallest = width;

        if (height < smallest) {
            smallest = height;
        }

        var radius =
            smallest.toFloat() / 2.0f;

        var centerY =
            height.toFloat() / 2.0f;

        var distanceY =
            y.toFloat() - centerY;

        var inside =
            (radius * radius)
            - (distanceY * distanceY);

        if (inside <= 0.0f) {
            return 0.0f;
        }

        return Math.sqrt(inside).toFloat();
    }

    private function getSafeLeft(
        width as Number,
        height as Number,
        y as Number,
        shape,
        padding as Number
    ) as Number {
        if (shape == System.SCREEN_SHAPE_ROUND) {
            var halfWidth =
                getRoundHalfWidth(width, height, y);

            return (
                (width.toFloat() / 2.0f)
                - halfWidth
            ).toNumber() + padding;
        }

        var ratio = 0.035f;

        if (
            shape == System.SCREEN_SHAPE_SEMI_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_OCTAGON
        ) {
            ratio = 0.080f;
        }

        return (
            width.toFloat() * ratio
        ).toNumber() + padding;
    }

    private function getSafeRight(
        width as Number,
        height as Number,
        y as Number,
        shape,
        padding as Number
    ) as Number {
        if (shape == System.SCREEN_SHAPE_ROUND) {
            var halfWidth =
                getRoundHalfWidth(width, height, y);

            return (
                (width.toFloat() / 2.0f)
                + halfWidth
            ).toNumber() - padding;
        }

        var ratio = 0.035f;

        if (
            shape == System.SCREEN_SHAPE_SEMI_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_OCTAGON
        ) {
            ratio = 0.080f;
        }

        return width
            - (width.toFloat() * ratio).toNumber()
            - padding;
    }

    //in storage we have some lines that tell what values are danger i want lines in the grapth to be able to see easy when that was
    private function setSavetyLines(
        dc as Graphics.Dc
    ){

    }
}