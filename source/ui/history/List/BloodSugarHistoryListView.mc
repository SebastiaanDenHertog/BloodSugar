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
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarHistoryListView extends WatchUi.View {
    const ZONE_DANGER_LOW = 0;
    const ZONE_LOW = 1;
    const ZONE_HIGH = 2;
    const ZONE_DANGER_HIGH = 3;

    private var _historyCount as Number;
    private var _useMgdl as Boolean;
    private var _dangerLow as Float;
    private var _low as Float;
    private var _high as Float;
    private var _dangerHigh as Float;
    private var _unit as String;
    private var _selected as Number;
    private var _showDetails as Boolean;

    public function initialize() {
        View.initialize();

        _historyCount = 0;
        _useMgdl = false;
        _dangerLow = 4.4f;
        _low = 5.0f;
        _high = 7.8f;
        _dangerHigh = 12.2f;
        _unit = "mmol/L";
        _selected = 0;
        _showDetails = false;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarHistoryListLayout(dc));
    }

    private function setLabel(id as String, value as String) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setText(value);
        }
    }

    private function setLabelColor(id as String, color as Number) as Void {
        var drawable = findDrawableById(id);

        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setColor(color);
        }
    }

    private function clearLayoutLabels() as Void {
        setLabel("historyListPosition", "");
        setLabel("historyListNoData", "");
        setLabel("historyDetailValue", "");
        setLabel("historyDetailUnit", "");
        setLabel("historyDetailZone", "");
        setLabel("historyDetailDate", "");
    }

    public function onShow() as Void {
        var current = WatchUi.getCurrentView();
        if (
            current.size() > 1 &&
            current[1] instanceof BloodSugarHistoryListDelegate
        ) {
            (current[1] as BloodSugarHistoryListDelegate).refresh();
        }
        WatchUi.requestUpdate();
    }

    public function setHistory(
        historyCount as Number,
        useMgdl as Boolean,
        dangerLow as Float,
        low as Float,
        high as Float,
        dangerHigh as Float,
        unit as String
    ) as Void {
        _historyCount = historyCount;
        _useMgdl = useMgdl;
        _dangerLow = dangerLow;
        _low = low;
        _high = high;
        _dangerHigh = dangerHigh;
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
        clearLayoutLabels();
        if (!hasValidData()) {
            setLabel("historyListNoData", "No history yet");
            View.onUpdate(dc);
            SafeText.drawBottom(dc, "BACK to return");
            return;
        }

        if (_showDetails) {
            updateDetailLayout();
            View.onUpdate(dc);
            SafeText.drawBottom(dc, "UP/DOWN browse \n SELECT list");
            return;
        }
        updatePositionLabel();
        View.onUpdate(dc);
        drawList(dc);
    }

    private function updatePositionLabel() as Void {
        var positionText =
            (_selected + 1).format("%d") + "/" + _historyCount.format("%d");

        setLabel("historyListPosition", positionText);
    }

    private function updateDetailLayout() as Void {
        var historyIndex = getSelectedHistoryIndex();
        if (historyIndex < 0) {
            setLabel("historyListNoData", "No history yet");
            return;
        }
        var valueMmol = BloodSugarStore.getReadingValueMmolAt(historyIndex);
        var timestamp = BloodSugarStore.getReadingTimeAt(historyIndex);

        if (valueMmol == null || timestamp == null) {
            setLabel("historyListNoData", "Reading unavailable");
            return;
        }

        var value = getDisplayValue(valueMmol as Float);
        var zoneColor = getValueColor(value);
        var positionText =
            (_selected + 1).format("%d") + " of " + _historyCount.format("%d");

        setLabel("historyListPosition", positionText);
        setLabel("historyDetailValue", formatValueOnly(value));
        setLabel("historyDetailUnit", _unit);
        setLabel("historyDetailZone", getZoneLabel(value));
        setLabel("historyDetailDate", formatDateTime(timestamp as Number));
        setLabelColor("historyDetailValue", zoneColor);
        setLabelColor("historyDetailZone", zoneColor);
    }

    private function hasValidData() as Boolean {
        return _historyCount > 0;
    }

    private function clampSelection() as Void {
        if (_historyCount == 0) {
            _selected = 0;
            return;
        }

        if (_selected < 0) {
            _selected = 0;
        }

        var lastPosition = _historyCount - 1;
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
        if (lastListIndex >= _historyCount) {
            lastListIndex = _historyCount - 1;
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
        var valueMmol = BloodSugarStore.getReadingValueMmolAt(listIndex);
        var timestamp = BloodSugarStore.getReadingTimeAt(listIndex);

        if (valueMmol == null || timestamp == null) {
            return;
        }

        var value = getDisplayValue(valueMmol as Float);
        var isSelected = listIndex == _selected;
        var valueColor = getValueColor(value);
        var distanceFromCenter = rowCenterY - height / 2;
        if (distanceFromCenter < 0) {
            distanceFromCenter = -distanceFromCenter;
        }
        var maximumDistance = height / 2;
        var distanceRatio =
            distanceFromCenter.toFloat() / maximumDistance.toFloat();
        var sideMargin = 2 + (distanceRatio * width * 0.18f).toNumber();
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
            formatDateTime(timestamp as Number),
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

    private function getValueColor(value as Float) as Number {
        if (value < _dangerLow || value > _dangerHigh) {
            return Graphics.COLOR_RED;
        }

        if (value < _low || value > _high) {
            return Graphics.COLOR_ORANGE;
        }

        return Graphics.COLOR_GREEN;
    }

    private function getZoneLabel(value as Float) as String {
        if (value < _dangerLow) {
            return "Danger low";
        }

        if (value < _low) {
            return "Low";
        }

        if (value > _dangerHigh) {
            return "Danger high";
        }

        if (value > _high) {
            return "High";
        }

        return "In range";
    }

    private function getDisplayValue(valueMmol as Float) as Float {
        if (_useMgdl) {
            return BloodSugarStore.MollToMgdl(valueMmol);
        }

        return valueMmol;
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
