import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class BloodSugarHomeView extends WatchUi.View {
    private var _reading;
    private var _useMgdl as Boolean;

    public function initialize() {
        View.initialize();
        _reading = null;
        _useMgdl = false;
    }

    public function onShow() as Void {
        refresh();
    }

    public function refresh() as Void {
        _reading = BloodSugarStore.getLatestReading();
        _useMgdl = BloodSugarStore.getUseMgdl();
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        SafeText.drawTop(dc, "Blood sugar");

        if (_reading == null || _reading.size() < 2) {
            dc.drawText(
                centerX,
                centerY - 15,
                Graphics.FONT_MEDIUM,
                "No readings",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            var valueMmol =
                _reading[BloodSugarStore.READING_VALUE_MMOL].toFloat();
            var valueText = BloodSugarStore.formatValue(valueMmol, _useMgdl);
            var unitText = BloodSugarStore.getUnitText(_useMgdl);

            dc.drawText(
                centerX,
                centerY - 35,
                Graphics.FONT_LARGE,
                valueText,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.drawText(
                centerX,
                centerY + 15,
                Graphics.FONT_XTINY,
                unitText,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.drawText(
                centerX,
                centerY + 42,
                Graphics.FONT_XTINY,
                getReadingSubtitle(),
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        SafeText.drawBottom(dc, "SELECT add new \n UP history");
    }

    private function getReadingSubtitle() as String {
        if (_reading == null) {
            return "";
        }

        var timestamp = _reading[BloodSugarStore.READING_TIME].toNumber();
        var elapsed = Time.now().value() - timestamp;
        var timeText;

        if (elapsed < 60) {
            timeText = "just now";
        } else if (elapsed < 3600) {
            timeText = (elapsed / 60).format("%d") + " min ago";
        } else if (elapsed < 86400) {
            timeText = (elapsed / 3600).format("%d") + " h ago";
        } else {
            timeText = (elapsed / 86400).format("%d") + " d ago";
        }

        var contextIndex = 0;

        if (_reading.size() > BloodSugarStore.READING_CONTEXT) {
            contextIndex = BloodSugarStore.getContextIndex(
                _reading[BloodSugarStore.READING_CONTEXT].toString()
            );
        }

        if (contextIndex == 0) {
            return timeText;
        }

        return timeText + " | " + BloodSugarStore.getContextLabel(contextIndex);
    }
}
