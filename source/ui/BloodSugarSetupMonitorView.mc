import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupMonitorView extends WatchUi.View {
    private var _select as Number;
    private var _bloodMonitors as Array<String>;
    function initialize() {
        View.initialize();
        _select = 0;
        _bloodMonitors = [];
    }

    public function setEntry(
        select as Number,
        bloodMonitors as Array<String>
    ) as Void {
        _bloodMonitors = bloodMonitors;
        _select = select;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, "Monitor");
        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_XTINY,
            "Choose your monitor",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        var monitorName = "No monitors available";

        if (
            _bloodMonitors.size() > 0 &&
            _select >= 0 &&
            _select < _bloodMonitors.size()
        ) {
            monitorName = _bloodMonitors[_select];
        }

        dc.drawText(
            centerX,
            centerY + 5,
            Graphics.FONT_MEDIUM,
            monitorName,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        SafeText.drawBottomWithPadding(
            dc,
            "SELECT to continue\nUP/DOWN change",
            12
        );
    }
}
