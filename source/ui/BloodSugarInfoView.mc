import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarInfoView extends WatchUi.View {
    private var _message as String;

    public function initialize() {
        View.initialize();
        _message = "";
    }

    public function setEntry(message as String) as Void {
        _message = message;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 4;

        dc.drawText(
            centerX,
            centerY,
            Graphics.FONT_XTINY,
            _message,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
