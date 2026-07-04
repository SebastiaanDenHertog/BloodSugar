import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarView extends WatchUi.View {
    private var _bloodSugar as Float;
    private var _stage as Number;
    private var _useMgdl as Boolean;

    public function initialize() {
        View.initialize();

        _bloodSugar = 0.0f;
        _stage = 0;
        _useMgdl = false;
    }

    public function onLayout(dc as Graphics.Dc) as Void {}

    public function setBloodSugar(
        bloodSugar as Float,
        stage as Number,
        useMgdl as Boolean
    ) as Void {
        _bloodSugar = bloodSugar;
        _stage = stage;
        _useMgdl = useMgdl;

        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.clear();

        if (_stage == 3) {
            drawUnitSelection(dc);
        } else {
            drawValueScreen(dc);
        }
    }

    private function drawValueScreen(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 65,
            Graphics.FONT_XTINY,
            getStageText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 15,
            Graphics.FONT_LARGE,
            getValueText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 55,
            Graphics.FONT_XTINY,
            getInstructionText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawUnitSelection(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 100,
            Graphics.FONT_XTINY,
            "Select unit",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 60,
            Graphics.FONT_LARGE,
            getValueText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        var unitText;

        if (!_useMgdl) {
            unitText = "mg/dL";
        } else {
            unitText = "mmol/L";
        }

        dc.drawText(
            centerX - 5,
            centerY + 15,
            Graphics.FONT_MEDIUM,
            unitText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 85,
            Graphics.FONT_XTINY,
            "UP/DOWN, then SELECT",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function getValueText() as String {
        return formatValue(_bloodSugar) + " " + getUnitText();
    }

    private function formatValue(value as Float) as String {
        return value.format("%.1f");
    }

    private function getUnitText() as String {
        if (_useMgdl) {
            return "mg/dL";
        }

        return "mmol/L";
    }

    private function getStageText() as String {
        if (_stage == 0) {
            return "Blood sugar";
        }

        if (_stage == 1) {
            return "Edit whole number";
        }

        if (_stage == 2) {
            return "Edit decimal";
        }

        if (_stage == 4) {
            return "Confirm reading";
        }

        return "";
    }

    private function getInstructionText() as String {
        if (_stage == 0) {
            return "SELECT to enter";
        }

        if (_stage == 1 || _stage == 2) {
            return "UP/DOWN, then SELECT";
        }

        if (_stage == 4) {
            return "SELECT to save";
        }

        return "";
    }
}
