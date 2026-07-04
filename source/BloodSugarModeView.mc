import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarModeView extends WatchUi.View {
    private var _stageSelect as Number;
    private var _stagePage as Number;

    public function initialize() {
        View.initialize();
        _stageSelect = 0;
        _stagePage = 0;
    }

    function onShow() as Void {}

    public function onUpdate(dc as Graphics.Dc) as Void {
        var font = Graphics.FONT_SYSTEM_TINY;
        var fontHeight = dc.getFontHeight(font);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            120,
            30,
            Graphics.FONT_MEDIUM,
            "Blood Sugar Setup",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            120 - (fontHeight + 5), // some extra room
            30,
            font,
            " do you have a blood glucose monitor that you wanne connect? ",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    public function onSelect() {
        if (_stageSelect == 0) {
            // Show confirmation dialog for blood glucose monitor connection
            var confirm = WatchUi.query(
                WatchUi.QUERY_CONFIRM,
                "Connect Monitor?",
                "Do you want to set up a blood glucose monitor?"
            );

            if (confirm == WatchUi.CONFIRM_YES) {
                _stageSelect = 1;
            }
        } else if (_stageSelect == 1) {
            // Navigate to BloodSugarSetup view
            WatchUi.pushView(new BloodSugarSetup());
        }
    }

    public function onNextPage() {
        if (_stagePage == 0) {
            // Show confirmation dialog for page navigation
            var confirm = WatchUi.query(
                WatchUi.QUERY_CONFIRM,
                "Go to View?",
                "Do you want to navigate to the blood sugar view?"
            );

            if (confirm == WatchUi.CONFIRM_YES) {
                _stagePage = 1;
            }
        } else if (_stagePage == 1) {
            // Navigate to BloodSugarView
            WatchUi.pushView(new BloodSugarView());
        }
    }

    function onHide() as Void {}
}
