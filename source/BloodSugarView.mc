import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarView extends WatchUi.View {
    private var _bloodSugar as Float;
    private var _stage as Number;
    private var _useMgdl as Boolean;
    private var _context as String;
    private var _message as String;
    private var _isEditing as Boolean;

    public function initialize() {
        View.initialize();
        _bloodSugar = 5.5f;
        _stage = 0;
        _useMgdl = false;
        _context = "No context";
        _message = "";
        _isEditing = false;
    }

    public function setEntry(
        bloodSugar as Float,
        stage as Number,
        useMgdl as Boolean,
        context as String,
        message as String,
        isEditing as Boolean
    ) as Void {
        _bloodSugar = bloodSugar;
        _stage = stage;
        _useMgdl = useMgdl;
        _context = context;
        _message = message;
        _isEditing = isEditing;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, getStageText());

        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_LARGE,
            formatValue(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 20,
            Graphics.FONT_XTINY,
            BloodSugarStore.getUnitText(_useMgdl),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_stage >= 1) {
            dc.drawText(
                centerX,
                centerY + 70,
                Graphics.FONT_XTINY,
                _context,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        var footer = getInstructionText();

        if (!_message.equals("")) {
            footer = _message;
        }

        SafeText.drawBottom(dc, footer);
    }

    private function formatValue() as String {
        if (_useMgdl) {
            return _bloodSugar.format("%.0f");
        }

        return _bloodSugar.format("%.1f");
    }

    private function getStageText() as String {
        if (_stage == 0) {
            if (_isEditing) {
                return "Edit measured value";
            }
            return "Set measured value";
        }
        if (_stage == 1) {
            if (_isEditing) {
                return "Edit context";
            }
            return "Measurement context";
        }
        if (_isEditing) {
            return "Confirm changes";
        }
        return "Confirm measurement";
    }

    private function getInstructionText() as String {
        if (_stage == 0) {
            return "UP/DOWN adjust\nSELECT next";
        }
        if (_stage == 1) {
            return "UP/DOWN context\nSELECT next";
        }

        if (_isEditing) {
            return "SELECT update\nBACK edit";
        }
        return "SELECT save\nBACK edit";
    }
}
