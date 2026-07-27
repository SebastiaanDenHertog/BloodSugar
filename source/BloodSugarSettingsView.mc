import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSettingsView extends WatchUi.View {
    private var _selected as Number;
    private var _useMgdl as Boolean;
    private var _dangerLowMmol as Float;
    private var _lowMmol as Float;
    private var _highMmol as Float;
    private var _dangerHighMmol as Float;
    private var _contextIndex as Number;
    private var _confirmBeforeSave as Boolean;
    private var _bleSupported as Boolean;
    private var _status as String;

    public function initialize() {
        View.initialize();
        _selected = 0;
        _useMgdl = false;
        _dangerLowMmol = BloodSugarStore.MgdlToMoll(80.0f);
        _lowMmol = BloodSugarStore.MgdlToMoll(90.0f);
        _highMmol = BloodSugarStore.MgdlToMoll(140.0f);
        _dangerHighMmol = BloodSugarStore.MgdlToMoll(220.0f);
        _contextIndex = 0;
        _confirmBeforeSave = true;
        _bleSupported = false;
        _status = "";
    }

    public function setState(
        selected as Number,
        useMgdl as Boolean,
        zones,
        contextIndex as Number,
        confirmBeforeSave as Boolean,
        bleSupported as Boolean,
        status as String
    ) as Void {
        _selected = selected;
        _useMgdl = useMgdl;
        _dangerLowMmol = zones[0].toFloat();
        _lowMmol = zones[1].toFloat();
        _highMmol = zones[2].toFloat();
        _dangerHighMmol = zones[3].toFloat();
        _contextIndex = contextIndex;
        _confirmBeforeSave = confirmBeforeSave;
        _bleSupported = bleSupported;
        _status = status;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 100,
            Graphics.FONT_MEDIUM,
            "Settings",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 48,
            Graphics.FONT_TINY,
            getItemTitle(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY,
            Graphics.FONT_MEDIUM,
            getItemValue(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        var instruction = "UP/DOWN change \n SELECT next";

        if (isActionItem()) {
            instruction = "SELECT open \n UP/DOWN next";
        }

        if (!_status.equals("")) {
            instruction = _status;
        }

        SafeText.drawBottom(dc, instruction);
    }

    private function getBleIndex() as Number {
        return 7;
    }

    private function getClearIndex() as Number {
        if (_bleSupported) {
            return 8;
        }

        return 7;
    }

    private function isActionItem() as Boolean {
        if (_bleSupported && _selected == getBleIndex()) {
            return true;
        }

        return _selected == getClearIndex();
    }

    private function getItemTitle() as String {
        if (_selected == 0) {
            return "Display unit";
        }
        if (_selected == 1) {
            return "Danger low";
        }
        if (_selected == 2) {
            return "Low limit";
        }
        if (_selected == 3) {
            return "High limit";
        }
        if (_selected == 4) {
            return "Danger high";
        }
        if (_selected == 5) {
            return "Default context";
        }
        if (_selected == 6) {
            return "Confirm before save";
        }
        if (_bleSupported && _selected == getBleIndex()) {
            return "Glucose monitor";
        }
        return "Delete history";
    }

    private function getItemValue() as String {
        if (_selected == 0) {
            return BloodSugarStore.getUnitText(_useMgdl);
        }

        if (_selected == 1) {
            return formatThreshold(_dangerLowMmol);
        }

        if (_selected == 2) {
            return formatThreshold(_lowMmol);
        }

        if (_selected == 3) {
            return formatThreshold(_highMmol);
        }

        if (_selected == 4) {
            return formatThreshold(_dangerHighMmol);
        }

        if (_selected == 5) {
            return BloodSugarStore.getContextLabel(_contextIndex);
        }

        if (_selected == 6) {
            if (_confirmBeforeSave) {
                return "On";
            }
            return "Off";
        }

        if (_bleSupported && _selected == getBleIndex()) {
            return "Set up BLE";
        }

        return "Delete all";
    }

    private function formatThreshold(valueMmol as Float) as String {
        return (
            BloodSugarStore.formatValue(valueMmol, _useMgdl) +
            " " +
            BloodSugarStore.getUnitText(_useMgdl)
        );
    }
}
