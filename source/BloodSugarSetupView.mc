import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupView extends WatchUi.View {
    private var _useMgdl as Boolean;

    public function initialize() {
        View.initialize();
        _useMgdl = BloodSugarStore.getUseMgdl();
    }

    public function setUseMgdl(useMgdl as Boolean) as Void {
        _useMgdl = useMgdl;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.drawText(
            centerX,
            centerY - 120,
            Graphics.FONT_MEDIUM,
            "Setup",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY - 35,
            Graphics.FONT_XTINY,
            "Choose your display unit",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            centerY + 5,
            Graphics.FONT_LARGE,
            BloodSugarStore.getUnitText(_useMgdl),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        SafeText.drawBottom(dc, "UP/DOWN change \n SELECT save");
    }
}
