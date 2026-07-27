import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSettingsView extends WatchUi.View {
    private var _selected as Number;
    private var _useMgdl as Boolean;
    private var _targetLowMmol as Float;
    private var _targetHighMmol as Float;
    private var _contextIndex as Number;
    private var _confirmBeforeSave as Boolean;
    private var _bleSupported as Boolean;
    private var _status as String;

    public function initialize() {
        View.initialize();
        _selected = 0;
        _useMgdl = false;
        _targetLowMmol = 4.0f;
        _targetHighMmol = 10.0f;
        _contextIndex = 0;
        _confirmBeforeSave = true;
        _bleSupported = false;
        _status = "";
    }

    public function setState(
        selected as Number,
        useMgdl as Boolean,
        targetLowMmol as Float,
        targetHighMmol as Float,
        contextIndex as Number,
        confirmBeforeSave as Boolean,
        bleSupported as Boolean,
        status as String
    ) as Void {
        _selected = selected;
        _useMgdl = useMgdl;
        _targetLowMmol = targetLowMmol;
        _targetHighMmol = targetHighMmol;
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

    private function getClearIndex() as Number {
        if (_bleSupported) {
            return 6;
        }

        return 5;
    }

    private function isActionItem() as Boolean {
        if (_bleSupported && _selected == 5) {
            return true;
        }

        return _selected == getClearIndex();
    }

    private function getItemTitle() as String {
        if (_selected == 0) {
            return "Display unit";
        }
        if (_selected == 1) {
            return "Target low";
        }
        if (_selected == 2) {
            return "Target high";
        }
        if (_selected == 3) {
            return "Default context";
        }
        if (_selected == 4) {
            return "Confirm before save";
        }
        if (_bleSupported && _selected == 5) {
            return "Glucose monitor";
        }
        return "Delete history";
    }

    private function getItemValue() as String {
        if (_selected == 0) {
            return BloodSugarStore.getUnitText(_useMgdl);
        }

        if (_selected == 1) {
            return formatTarget(_targetLowMmol);
        }

        if (_selected == 2) {
            return formatTarget(_targetHighMmol);
        }

        if (_selected == 3) {
            return BloodSugarStore.getContextLabel(_contextIndex);
        }

        if (_selected == 4) {
            if (_confirmBeforeSave) {
                return "On";
            }
            return "Off";
        }

        if (_bleSupported && _selected == 5) {
            return "Set up BLE";
        }

        return "Delete all";
    }

    private function formatTarget(valueMmol as Float) as String {
        return (
            BloodSugarStore.formatValue(valueMmol, _useMgdl) +
            " " +
            BloodSugarStore.getUnitText(_useMgdl)
        );
    }
}
