import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupView extends WatchUi.View {
    private var _status as String = "Tap Search to Start";
    private var _deviceName as String = "";
    private var _isScanning as Boolean = false;

    public function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        //setLayout(Rez.Layouts.BloodSugarSetupLayout(dc));
    }

    function onShow() as Void {}

    public function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw title
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            120,
            30,
            Graphics.FONT_MEDIUM,
            "Blood Sugar Setup",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw status
        var y = 80;
        if (_isScanning) {
            _status = "Searching...";
        }
        dc.drawText(
            120,
            y,
            Graphics.FONT_LARGE,
            _status,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += 50;

        // Show device name if found
        if (_deviceName) {
            dc.drawText(
                120,
                y,
                Graphics.FONT_MEDIUM,
                "Found: " + _deviceName,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function onHide() as Void {}

    public function setStatus(status as String) as Void {
        _status = status;
        WatchUi.requestUpdate();
    }

    public function setDeviceName(name as String) as Void {
        _deviceName = name;
        WatchUi.requestUpdate();
    }

    public function setIsScanning(scanning as Boolean) as Void {
        _isScanning = scanning;
        WatchUi.requestUpdate();
    }
}
