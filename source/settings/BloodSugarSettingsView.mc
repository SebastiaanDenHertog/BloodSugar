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

class BloodSugarSettingsView extends WatchUi.View {
    const MODE_MAIN = 0;
    const MODE_ZONES = 1;
    const MAIN_ITEM_COUNT = 9;
    const ZONE_ITEM_COUNT = 4;
    private var _mode as Number;
    private var _selected as Number;
    private var _zoneSelected as Number;
    private var _editing as Boolean;
    private var _useMgdl as Boolean;
    private var _dangerLowMmol as Float;
    private var _lowMmol as Float;
    private var _highMmol as Float;
    private var _dangerHighMmol as Float;
    private var _notificationsEnabled as Boolean;
    private var _notificationLowMmol as Float;
    private var _notificationHighMmol as Float;
    private var _contextIndex as Number;
    private var _confirmBeforeSave as Boolean;
    private var _status as String;
    private var _savedMode as Number;
    private var _savedIndex as Number;

    public function initialize() {
        View.initialize();
        _mode = MODE_MAIN;
        _selected = 0;
        _zoneSelected = 0;
        _editing = false;
        _useMgdl = false;
        _dangerLowMmol = BloodSugarStore.MgdlToMoll(80.0f);
        _lowMmol = BloodSugarStore.MgdlToMoll(90.0f);
        _highMmol = BloodSugarStore.MgdlToMoll(140.0f);
        _dangerHighMmol = BloodSugarStore.MgdlToMoll(220.0f);
        _notificationsEnabled = true;
        _notificationLowMmol = BloodSugarStore.MgdlToMoll(70.0f);
        _notificationHighMmol = BloodSugarStore.MgdlToMoll(180.0f);
        _contextIndex = 0;
        _confirmBeforeSave = true;
        _status = "";
        _savedMode = -1;
        _savedIndex = -1;
    }

    public function setState(state as SettingsState) as Void {
        _mode = state.mode;
        _selected = state.selected;
        _zoneSelected = state.zoneSelected;
        _editing = state.editing;
        _useMgdl = state.useMgdl;

        if (state.zones.size() >= 4) {
            _dangerLowMmol = state.zones[0].toFloat();
            _lowMmol = state.zones[1].toFloat();
            _highMmol = state.zones[2].toFloat();
            _dangerHighMmol = state.zones[3].toFloat();
        }

        _notificationsEnabled = state.notificationsEnabled;
        _notificationLowMmol = state.notificationLowMmol;
        _notificationHighMmol = state.notificationHighMmol;
        _contextIndex = state.contextIndex;
        _confirmBeforeSave = state.confirmBeforeSave;
        _status = state.status;
        _savedMode = state.savedMode;
        _savedIndex = state.savedIndex;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        drawHeader(dc);
        drawSectionHeader(dc);
        if (_mode == MODE_ZONES) {
            drawZoneList(dc);
        } else {
            drawMainList(dc);
        }
        drawInstructions(dc);
    }

    private function drawSectionHeader(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var sectionY = getSectionY(dc);
        var title = getSectionTitle();
        var color = Graphics.COLOR_WHITE;
        if (_mode == MODE_MAIN && _selected == 8) {
            color = Graphics.COLOR_RED;
        }

        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(
            (width * 8) / 100,
            sectionY,
            Graphics.FONT_XTINY,
            title,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var lineY = sectionY + dc.getFontHeight(Graphics.FONT_XTINY) + 1;
        dc.drawLine((width * 8) / 100, lineY, (width * 92) / 100, lineY);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    private function getSectionTitle() as String {
        if (_mode == MODE_ZONES) {
            return "GLUCOSE ZONES";
        }
        if (_selected <= 3) {
            return "GENERAL";
        }
        if (_selected == 4) {
            return "MONITOR";
        }
        if (_selected <= 7) {
            return "NOTIFICATIONS";
        }
        return "DANGER";
    }

    private function drawHeader(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var title = "Settings";
        if (_mode == MODE_ZONES) {
            title = "Glucose zones";
        }
        var titleFont = Graphics.FONT_MEDIUM;
        if (height < 220) {
            titleFont = Graphics.FONT_SMALL;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            width / 2,
            2,
            titleFont,
            title,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
    private function getSectionY(dc as Graphics.Dc) as Number {
        var titleFont = Graphics.FONT_MEDIUM;
        if (dc.getHeight() < 220) {
            titleFont = Graphics.FONT_SMALL;
        }
        return 2 + dc.getFontHeight(titleFont) + 2;
    }

    private function drawMainList(dc as Graphics.Dc) as Void {
        drawSectionList(dc, _selected);
    }

    private function drawZoneList(dc as Graphics.Dc) as Void {
        drawList(dc, _zoneSelected, ZONE_ITEM_COUNT, true);
    }

    private function getListStartY(dc as Graphics.Dc) as Number {
        var sectionY = getSectionY(dc);
        return sectionY + dc.getFontHeight(Graphics.FONT_XTINY) + 5;
    }

    private function drawSectionList(
        dc as Graphics.Dc,
        selectedIndex as Number
    ) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var rowWidth = (width * 88) / 100;
        var rowHeight = (height * 12) / 100;
        var startY = getListStartY(dc);
        var centerX = width / 2;
        var sectionStart = getSectionStart(selectedIndex);
        var sectionEnd = getSectionEnd(selectedIndex);
        var row = 0;
        for (var index = sectionStart; index <= sectionEnd; index += 1) {
            var y = startY + row * rowHeight;
            var isSelected = index == selectedIndex;
            var isSaved =
                isSelected && _savedMode == MODE_MAIN && _savedIndex == index;
            var isDanger = index == 8;
            drawRow(
                dc,
                centerX,
                y,
                rowWidth,
                rowHeight - 3,
                getMainTitle(index),
                getMainValue(index),
                isSelected,
                isSaved,
                isDanger
            );

            row += 1;
        }
    }

    private function drawList(
        dc as Graphics.Dc,
        selectedIndex as Number,
        itemCount as Number,
        zoneList as Boolean
    ) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var rowWidth = (width * 88) / 100;
        var rowHeight = (height * 11) / 100;
        var startY = (height * 26) / 100;
        var centerX = width / 2;
        var visibleCount = 5;
        var firstIndex = selectedIndex - 2;

        if (firstIndex < 0) {
            firstIndex = 0;
        }

        var maxFirstIndex = itemCount - visibleCount;

        if (maxFirstIndex < 0) {
            maxFirstIndex = 0;
        }

        if (firstIndex > maxFirstIndex) {
            firstIndex = maxFirstIndex;
        }

        for (var row = 0; row < visibleCount; row += 1) {
            var index = firstIndex + row;
            if (index >= itemCount) {
                break;
            }
            var y = startY + row * rowHeight;
            var title = "";
            var value = "";
            if (zoneList) {
                title = getZoneTitle(index);
                value = getZoneValue(index);
            } else {
                title = getMainTitle(index);
                value = getMainValue(index);
            }
            var isSelected = index == selectedIndex;
            var isSaved =
                isSelected && _savedMode == _mode && _savedIndex == index;
            var isDanger = !zoneList && index == 8;
            drawRow(
                dc,
                centerX,
                y,
                rowWidth,
                rowHeight - 3,
                title,
                value,
                isSelected,
                isSaved,
                isDanger
            );
        }
    }

    private function drawRow(
        dc as Graphics.Dc,
        centerX as Number,
        y as Number,
        width as Number,
        height as Number,
        title as String,
        value as String,
        selected as Boolean,
        saved as Boolean,
        danger as Boolean
    ) as Void {
        var x = centerX - width / 2;
        var font = Graphics.FONT_XTINY;
        var fontHeight = dc.getFontHeight(font);
        var textY = y + (height - fontHeight) / 2;
        var padding = 6;
        var gap = 6;
        if (selected && saved) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
            dc.fillRectangle(x, y, width, height);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_GREEN);
        } else if (selected && danger) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillRectangle(x, y, width, height);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_RED);
        } else if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(x, y, width, height);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else if (danger) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        var availableWidth = width - padding * 2;
        var maximumValueWidth = (availableWidth * 42) / 100;
        var valueText = shortenToWidth(dc, value, font, maximumValueWidth);
        var valueWidth = dc.getTextWidthInPixels(valueText, font);
        var maximumTitleWidth = availableWidth - valueWidth - gap;
        if (maximumTitleWidth < 1) {
            maximumTitleWidth = 1;
        }
        var titleText = shortenToWidth(dc, title, font, maximumTitleWidth);
        dc.drawText(
            x + padding,
            textY,
            font,
            titleText,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            x + width - padding,
            textY,
            font,
            valueText,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    private function getSectionStart(index as Number) as Number {
        if (index <= 3) {
            return 0;
        }
        if (index == 4) {
            return 4;
        }
        if (index <= 7) {
            return 5;
        }
        return 8;
    }

    private function getSectionEnd(index as Number) as Number {
        if (index <= 3) {
            return 3;
        }
        if (index == 4) {
            return 4;
        }
        if (index <= 7) {
            return 7;
        }
        return 8;
    }

    private function drawInstructions(dc as Graphics.Dc) as Void {
        var instruction = "UP/DOWN move\nSELECT open";
        if (_editing) {
            instruction = "UP/DOWN change\nSELECT done";
        } else if (_mode == MODE_ZONES) {
            instruction = "UP/DOWN move\nSELECT edit";
        }
        if (!_status.equals("")) {
            instruction = _status;
        }
        SafeText.drawBottom(dc, instruction);
    }

    private function getMainTitle(index as Number) as String {
        if (index == 0) {
            return "Display unit";
        }
        if (index == 1) {
            return "Glucose zones";
        }
        if (index == 2) {
            return "Default context";
        }
        if (index == 3) {
            return "Confirm save";
        }
        if (index == 4) {
            return "Monitor setup";
        }
        if (index == 5) {
            return "Notifications";
        }
        if (index == 6) {
            return "Low notification";
        }
        if (index == 7) {
            return "High notification";
        }
        return "Delete all history";
    }

    private function getMainValue(index as Number) as String {
        if (index == 0) {
            return BloodSugarStore.getUnitText(_useMgdl);
        }
        if (index == 1) {
            return "Open";
        }
        if (index == 2) {
            return BloodSugarStore.getContextLabel(_contextIndex);
        }
        if (index == 3) {
            return getOnOff(_confirmBeforeSave);
        }
        if (index == 4) {
            return "Open";
        }
        if (index == 5) {
            return getOnOff(_notificationsEnabled);
        }
        if (index == 6) {
            return formatThreshold(_notificationLowMmol);
        }
        if (index == 7) {
            return formatThreshold(_notificationHighMmol);
        }
        return "DELETE";
    }

    private function getZoneTitle(index as Number) as String {
        if (index == 0) {
            return "Danger low";
        }
        if (index == 1) {
            return "Low limit";
        }
        if (index == 2) {
            return "High limit";
        }
        return "Danger high";
    }

    private function getZoneValue(index as Number) as String {
        if (index == 0) {
            return formatThreshold(_dangerLowMmol);
        }
        if (index == 1) {
            return formatThreshold(_lowMmol);
        }
        if (index == 2) {
            return formatThreshold(_highMmol);
        }
        return formatThreshold(_dangerHighMmol);
    }

    private function formatThreshold(valueMmol as Float) as String {
        return (
            BloodSugarStore.formatValue(valueMmol, _useMgdl) +
            " " +
            BloodSugarStore.getUnitText(_useMgdl)
        );
    }

    private function getOnOff(value as Boolean) as String {
        if (value) {
            return "On";
        }
        return "Off";
    }

    private function wrapIndex(index as Number, itemCount as Number) as Number {
        while (index < 0) {
            index += itemCount;
        }
        while (index >= itemCount) {
            index -= itemCount;
        }
        return index;
    }

    private function shortenToWidth(
        dc as Graphics.Dc,
        value as String,
        font,
        maximumWidth as Number
    ) as String {
        if (dc.getTextWidthInPixels(value, font) <= maximumWidth) {
            return value;
        }

        var ellipsis = "...";

        /*
         * If even "..." does not fit,
         * return an empty string.
         */
        if (dc.getTextWidthInPixels(ellipsis, font) > maximumWidth) {
            return "";
        }

        var endIndex = value.length();

        while (endIndex > 0) {
            var shortened = value.substring(0, endIndex) + ellipsis;

            if (dc.getTextWidthInPixels(shortened, font) <= maximumWidth) {
                return shortened;
            }

            endIndex -= 1;
        }

        return ellipsis;
    }
}
