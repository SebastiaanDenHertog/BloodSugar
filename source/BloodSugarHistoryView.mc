import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class BloodSugarHistoryView extends WatchUi.View {

    private const _sensorLabel = "Blood Sugar";
    var value; 

    public function initialize() {
        value = BloodSugarStore.getHistory();
        View.initialize();
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // if (value) {
        //     var graphBottom = dc.getHeight() / 2 + 45;
        //     var graphHeight = 90;
        //     var graphWidth = (dc.getWidth() - (2 * x));
        //     var dataOffset = value[1].getMin();
        //     var dataScale = _sensorRange.toFloat();
        //     var gotValidData = false;
        //     dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);

        //     var xStep = 1.0f * graphWidth / (_sensorSamples- 1);

        //     var i = 0;

        //     var font = Graphics.FONT_XTINY;
        //     var fontHeight = dc.getFontHeight(font);

        //     // draw the min/max hr values
        //     dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        //     if (max == null) {
        //         max = "?";
        //     } else {
        //         max = max.format("%d");
        //     }

        //     if (min == null) {
        //         min = "?";
        //     } else {
        //         min = min.format("%d");
        //     }
        //     dc.drawText(dc.getWidth() / 2, 1 * fontHeight, font, _sensorLabel[_index], Graphics.TEXT_JUSTIFY_CENTER);
        //     dc.drawText(dc.getWidth() / 2, 2 * fontHeight, font, "Min: " + min + " Max: " + max, Graphics.TEXT_JUSTIFY_CENTER);

        //     // draw the start/end times
        //     if ((firstSampleTime != null) && (lastSampleTime != null)) {
        //         var startInfo = Gregorian.info(firstSampleTime, Time.FORMAT_SHORT);
        //         var endInfo = Gregorian.info(lastSampleTime, Time.FORMAT_SHORT);

        //         var startString = Lang.format("$1$/$2$ $3$:$4$:$5$", [
        //             (startInfo.month as Number).format("%d"),
        //             startInfo.day.format("%d"),
        //             startInfo.hour.format("%02d"),
        //             startInfo.min.format("%02d"),
        //             startInfo.sec.format("%02d")
        //         ]);

        //         var endString = Lang.format("$1$/$2$ $3$:$4$:$5$", [
        //             (endInfo.month as Number).format("%d"),
        //             endInfo.day.format("%d"),
        //             endInfo.hour.format("%02d"),
        //             endInfo.min.format("%02d"),
        //             endInfo.sec.format("%02d")
        //         ]);

        //         dc.drawText(dc.getWidth() / 2, dc.getHeight() - (3 * fontHeight), font, "Start: " + startString, Graphics.TEXT_JUSTIFY_CENTER);
        //         dc.drawText(dc.getWidth() / 2, dc.getHeight() - (2 * fontHeight), font, "End: " + endString, Graphics.TEXT_JUSTIFY_CENTER);
        //     }
        // } 

    }
}
