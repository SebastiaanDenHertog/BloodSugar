import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupUnitView extends WatchUi.View {
    private var _useMgdl as Boolean;
    private var _useBloodMonitor as Boolean;

    private var _stage as Number;

    public function initialize() {
        View.initialize();
        _useMgdl = BloodSugarStore.getUseMgdl();
        _useBloodMonitor = BloodSugarStore.getUseBloodMonitor();
        _stage = 0;
    }

    public function setEntry(
        useMgdl as Boolean,
        stage as Number,
        useBloodMonitor as Boolean
    ) as Void {
        _useMgdl = useMgdl;
        _stage = stage;
        _useBloodMonitor = useBloodMonitor;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        SafeText.drawTop(dc, "Setup");

        if (_stage == 0) {
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

            SafeText.drawBottom(dc, "UP/DOWN change\nSELECT save");
        }
        if (_stage == 1) {
            dc.drawText(
                centerX,
                centerY - 35,
                Graphics.FONT_XTINY,
                "Do you want to connect\na blood monitor?",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.drawText(
                centerX,
                centerY + 5,
                Graphics.FONT_LARGE,
                BloodSugarStore.getBloodMonitorText(_useBloodMonitor),
                Graphics.TEXT_JUSTIFY_CENTER
            );

            SafeText.drawBottom(dc, "UP/DOWN change\nSELECT save");
        }
    }
}
