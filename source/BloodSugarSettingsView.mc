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
    }

    public function setState(
        mode as Number,
        selected as Number,
        zoneSelected as Number,
        editing as Boolean,
        useMgdl as Boolean,
        zones as Array<Float>,
        notificationsEnabled as Boolean,
        notificationLowMmol as Float,
        notificationHighMmol as Float,
        contextIndex as Number,
        confirmBeforeSave as Boolean,
        status as String
    ) as Void {
        _mode = mode;
        _selected = selected;
        _zoneSelected = zoneSelected;
        _editing = editing;
        _useMgdl = useMgdl;

        _dangerLowMmol = zones[0].toFloat();
        _lowMmol = zones[1].toFloat();
        _highMmol = zones[2].toFloat();
        _dangerHighMmol = zones[3].toFloat();

        _notificationsEnabled = notificationsEnabled;
        _notificationLowMmol = notificationLowMmol;
        _notificationHighMmol = notificationHighMmol;
        _contextIndex = contextIndex;
        _confirmBeforeSave = confirmBeforeSave;
        _status = status;

        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        drawHeader(dc);
        if (_mode == MODE_ZONES) {
            drawZoneList(dc);
        } else {
            drawMainList(dc);
        }
        drawInstructions(dc);
    }

    private function drawHeader(dc as Graphics.Dc) as Void {
        var title = "Settings";

        if (_mode == MODE_ZONES) {
            title = "Glucose zones";
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            (dc.getHeight() * 6) / 100,
            Graphics.FONT_MEDIUM,
            title,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawMainList(dc as Graphics.Dc) as Void {
        drawList(dc, _selected, MAIN_ITEM_COUNT, false);
    }

    private function drawZoneList(dc as Graphics.Dc) as Void {
        drawList(dc, _zoneSelected, ZONE_ITEM_COUNT, true);
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
        var rowHeight = (height * 13) / 100;
        var startY = (height * 22) / 100;
        var centerX = width / 2;
        for (var offset = -2; offset <= 2; offset += 1) {
            var index = wrapIndex(selectedIndex + offset, itemCount);
            var y = startY + (offset + 2) * rowHeight;
            var title = "";
            var value = "";
            if (zoneList) {
                title = getZoneTitle(index);
                value = getZoneValue(index);
            } else {
                title = getMainTitle(index);
                value = getMainValue(index);
            }
            drawRow(
                dc,
                centerX,
                y,
                rowWidth,
                rowHeight - 4,
                title,
                value,
                offset == 0
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
        selected as Boolean
    ) as Void {
        var x = centerX - width / 2;
        var font = Graphics.FONT_XTINY;
        var textY = y + (height - dc.getFontHeight(font)) / 2;
        var padding = 10;
        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(x, y, width, height);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }

        dc.drawText(
            x + padding,
            textY,
            font,
            shorten(title, 18),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            x + width - padding,
            textY,
            font,
            shorten(value, 14),
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
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
            return "Monitor setup";
        }
        if (index == 3) {
            return "Notifications";
        }
        if (index == 4) {
            return "Low notification";
        }
        if (index == 5) {
            return "High notification";
        }
        if (index == 6) {
            return "Default context";
        }
        if (index == 7) {
            return "Confirm save";
        }
        return "Delete history";
    }

    private function getMainValue(index as Number) as String {
        if (index == 0) {
            return BloodSugarStore.getUnitText(_useMgdl);
        }
        if (index == 1) {
            return "Open";
        }
        if (index == 2) {
            return "Open";
        }
        if (index == 3) {
            return getOnOff(_notificationsEnabled);
        }
        if (index == 4) {
            return formatThreshold(_notificationLowMmol);
        }
        if (index == 5) {
            return formatThreshold(_notificationHighMmol);
        }
        if (index == 6) {
            return BloodSugarStore.getContextLabel(_contextIndex);
        }
        if (index == 7) {
            return getOnOff(_confirmBeforeSave);
        }
        return "Delete";
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

    private function shorten(
        value as String,
        maximumLength as Number
    ) as String {
        if (value.length() <= maximumLength) {
            return value;
        }
        return value.substring(0, maximumLength - 3) + "...";
    }
}
