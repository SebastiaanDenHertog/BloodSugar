import Toybox.Graphics;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarHistoryListView extends WatchUi.View {
    const ZONE_DANGER_LOW = 0;
    const ZONE_LOW = 1;
    const ZONE_HIGH = 2;
    const ZONE_DANGER_HIGH = 3;

    private var _bloodSugar;
    private var _time;
    private var _zones;
    private var _unit as String;

    private var _selected as Number;

    private var _showDetails as Boolean;

    public function initialize() {
        View.initialize();

        _bloodSugar = [];
        _time = [];

        _zones = [4.4f, 5.0f, 7.8f, 12.2f];

        _unit = "mmol/L";
        _selected = 0;
        _showDetails = false;
    }

    public function onShow() as Void {
        WatchUi.requestUpdate();
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

        clampSelection();
        WatchUi.requestUpdate();
    }

    public function setBloodSugarSelect(selectedIndex as Number) as Void {
        _selected = selectedIndex - 1;

        clampSelection();
        WatchUi.requestUpdate();
    }

    public function moveSelection(change as Number) as Void {
        if (!hasValidData()) {
            return;
        }

        _selected += change;
        clampSelection();

        WatchUi.requestUpdate();
    }

    public function toggleDetails() as Void {
        if (!hasValidData()) {
            return;
        }

        _showDetails = !_showDetails;
        WatchUi.requestUpdate();
    }

    public function closeDetails() as Boolean {
        if (!_showDetails) {
            return false;
        }

        _showDetails = false;
        WatchUi.requestUpdate();

        return true;
    }

    public function isShowingDetails() as Boolean {
        return _showDetails;
    }

    public function getSelectedHistoryIndex() as Number {
        if (!hasValidData()) {
            return -1;
        }

        return _selected;
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.clear();

        if (!hasValidData()) {
            drawNoData(dc);
            return;
        }

        if (_showDetails) {
            drawSelectedDetails(dc);
            return;
        }

        drawList(dc);
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

    private function clampSelection() as Void {
        if (_bloodSugar == null || _bloodSugar.size() == 0) {
            _selected = 0;
            return;
        }

        if (_selected < 0) {
            _selected = 0;
        }

        var lastPosition = _bloodSugar.size() - 1;
        if (_selected > lastPosition) {
            _selected = lastPosition;
        }
    }

    private function drawNoData(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            centerY - dc.getFontHeight(Graphics.FONT_SMALL),
            Graphics.FONT_SMALL,
            "No history yet",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        SafeText.drawBottom(dc, "BACK to return");
    }

    private function drawList(dc as Graphics.Dc) as Void {
        var height = dc.getHeight();

        var rowFont = Graphics.FONT_XTINY;
        var rowHeight = dc.getFontHeight(rowFont) + 14;

        var centerY = height / 2;

        var visibleDistance = (height / 2 / rowHeight).toNumber() + 1;

        var firstListIndex = _selected - visibleDistance;

        var lastListIndex = _selected + visibleDistance;

        if (firstListIndex < 0) {
            firstListIndex = 0;
        }

        if (lastListIndex >= _bloodSugar.size()) {
            lastListIndex = _bloodSugar.size() - 1;
        }

        for (
            var listIndex = firstListIndex;
            listIndex <= lastListIndex;
            listIndex++
        ) {
            var rowOffset = listIndex - _selected;

            var rowCenterY = centerY + rowOffset * rowHeight;

            drawRow(dc, listIndex, rowCenterY, rowHeight);
        }

        drawPositionIndicator(dc);
    }

    private function drawPositionIndicator(dc as Graphics.Dc) as Void {
        var positionText =
            (_selected + 1).format("%d") +
            "/" +
            _bloodSugar.size().format("%d");

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);

        dc.drawText(
            dc.getWidth() / 2,
            4,
            Graphics.FONT_XTINY,
            positionText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawRow(
        dc as Graphics.Dc,
        listIndex as Number,
        rowCenterY as Number,
        rowHeight as Number
    ) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var rowTop = rowCenterY - rowHeight / 2;

        var rowBottom = rowCenterY + rowHeight / 2;

        if (rowBottom < 0 || rowTop > height) {
            return;
        }

        var historyIndex = listIndex;

        var value = _bloodSugar[historyIndex].toFloat();

        var timestamp = _time[historyIndex].toNumber();

        var isSelected = listIndex == _selected;

        var valueColor = getValueColor(value);

        var distanceFromCenter = rowCenterY - height / 2;

        if (distanceFromCenter < 0) {
            distanceFromCenter = -distanceFromCenter;
        }

        var maximumDistance = height / 2;

        var distanceRatio =
            distanceFromCenter.toFloat() / maximumDistance.toFloat();

        var sideMargin = 10 + (distanceRatio * width * 0.18f).toNumber();

        var left = sideMargin;
        var right = width - sideMargin;

        if (isSelected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

            dc.fillRectangle(left, rowTop, right - left, rowHeight);
        }

        dc.setColor(valueColor, Graphics.COLOR_BLACK);

        dc.fillRectangle(left + 4, rowTop + 4, 5, rowHeight - 8);

        var textColor = Graphics.COLOR_WHITE;
        var textBackground = Graphics.COLOR_BLACK;

        if (isSelected) {
            textColor = Graphics.COLOR_BLACK;
            textBackground = Graphics.COLOR_WHITE;
        }

        dc.setColor(textColor, textBackground);

        var textY = rowCenterY - dc.getFontHeight(Graphics.FONT_XTINY) / 2;

        dc.drawText(
            left + 14,
            textY,
            Graphics.FONT_XTINY,
            formatDateTime(timestamp),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            right - 5,
            textY,
            Graphics.FONT_XTINY,
            formatValue(value),
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    private function drawSelectedDetails(dc as Graphics.Dc) as Void {
        var historyIndex = getSelectedHistoryIndex();

        if (historyIndex < 0) {
            drawNoData(dc);
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();

        var centerX = width / 2;

        var value = _bloodSugar[historyIndex].toFloat();

        var timestamp = _time[historyIndex].toNumber();

        var zoneColor = getValueColor(value);

        var positionText =
            (_selected + 1).format("%d") +
            " of " +
            _bloodSugar.size().format("%d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            8,
            Graphics.FONT_XTINY,
            positionText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(zoneColor, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            (height * 0.25f).toNumber(),
            Graphics.FONT_NUMBER_MEDIUM,
            formatValueOnly(value),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            (height * 0.53f).toNumber(),
            Graphics.FONT_SMALL,
            _unit,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(zoneColor, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            (height * 0.66f).toNumber(),
            Graphics.FONT_SMALL,
            getZoneLabel(value),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            (height * 0.77f).toNumber(),
            Graphics.FONT_XTINY,
            formatDateTime(timestamp),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        SafeText.drawBottomWithPadding(dc, "UP/DOWN browse \n SELECT list");
    }

    private function getValueColor(value as Float) as Number {
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

    private function getZoneLabel(value as Float) as String {
        if (value < _zones[ZONE_DANGER_LOW].toFloat()) {
            return "Danger low";
        }

        if (value < _zones[ZONE_LOW].toFloat()) {
            return "Low";
        }

        if (value > _zones[ZONE_DANGER_HIGH].toFloat()) {
            return "Danger high";
        }

        if (value > _zones[ZONE_HIGH].toFloat()) {
            return "High";
        }

        return "In range";
    }

    private function formatValue(value as Float) as String {
        return formatValueOnly(value) + " " + _unit;
    }

    private function formatValueOnly(value as Float) as String {
        if (_unit.equals("mg/dL")) {
            return value.format("%.0f");
        }

        return value.format("%.1f");
    }

    private function formatDateTime(timestamp as Number) as String {
        var moment = new Time.Moment(timestamp);

        var info = Gregorian.info(moment, Time.FORMAT_SHORT);

        return (
            info.day.format("%02d") +
            "/" +
            info.month.format("%02d") +
            " " +
            info.hour.format("%02d") +
            ":" +
            info.min.format("%02d")
        );
    }
}
