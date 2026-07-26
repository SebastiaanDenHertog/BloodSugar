import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarModeView extends WatchUi.View {
    public function initialize() {
        View.initialize();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 70,
            Graphics.FONT_MEDIUM,
            "Glucose monitor",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 10,
            Graphics.FONT_XTINY,
            "Connect a supported BLE monitor?",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 55,
            Graphics.FONT_XTINY,
            "SELECT yes | BACK no",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
