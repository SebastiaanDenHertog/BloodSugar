import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarView extends WatchUi.View {
    private var _bloodSugar as Float;
    private var _stage as Number;
    private var _useMgdl as Boolean;
    private var _context as String;
    private var _message as String;

    public function initialize() {
        View.initialize();
        _bloodSugar = 5.5f;
        _stage = 0;
        _useMgdl = false;
        _context = "No context";
        _message = "";
    }

    public function setEntry(
        bloodSugar as Float,
        stage as Number,
        useMgdl as Boolean,
        context as String,
        message as String
    ) as Void {
        _bloodSugar = bloodSugar;
        _stage = stage;
        _useMgdl = useMgdl;
        _context = context;
        _message = message;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 90,
            Graphics.FONT_XTINY,
            getStageText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 35,
            Graphics.FONT_LARGE,
            formatValue(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 12,
            Graphics.FONT_XTINY,
            BloodSugarStore.getUnitText(_useMgdl),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_stage >= 2) {
            dc.drawText(
                centerX,
                centerY + 42,
                Graphics.FONT_XTINY,
                _context,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        var footer = getInstructionText();

        if (!_message.equals("")) {
            footer = _message;
        }

        dc.drawText(
            centerX,
            dc.getHeight() - 42,
            Graphics.FONT_XTINY,
            footer,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function formatValue() as String {
        if (_useMgdl) {
            return _bloodSugar.format("%.0f");
        }

        return _bloodSugar.format("%.1f");
    }

    private function getStageText() as String {
        if (_stage == 0) {
            return "New measurement";
        }
        if (_stage == 1) {
            return "Set measured value";
        }
        if (_stage == 2) {
            return "Measurement context";
        }
        return "Confirm measurement";
    }

    private function getInstructionText() as String {
        if (_stage == 0) {
            return "SELECT to start";
        }
        if (_stage == 1) {
            return "UP/DOWN adjust | SELECT next";
        }
        if (_stage == 2) {
            return "UP/DOWN context | SELECT next";
        }
        return "SELECT save | BACK edit";
    }
}
