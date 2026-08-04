import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSetupBleView extends WatchUi.View {
    private var _status as String = "Tap Search to Start";
    private var _deviceName as String = "";
    private var _isScanning as Boolean = false;

    public function initialize() {
        View.initialize();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var totalWidth = dc.getWidth();
        SafeText.drawTop(dc, "Setup");

        var y = 100;
        if (_isScanning) {
            _status = "Searching...";
        }
        dc.drawText(
            totalWidth / 2,
            y,
            Graphics.FONT_SMALL,
            _status,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += 50;

        if (_deviceName != null) {
            dc.drawText(
                totalWidth / 2,
                y,
                Graphics.FONT_SMALL,
                "Found:" + _deviceName,
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
