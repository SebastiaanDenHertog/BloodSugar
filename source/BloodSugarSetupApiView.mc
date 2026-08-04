import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiView extends WatchUi.View {
    private var _selected as Number;
    private var _username as String;
    private var _passwordLength as Number;
    private var _status as String;
    private var _busy as Boolean;

    public function initialize() {
        View.initialize();

        _selected = 0;
        _username = "";
        _passwordLength = 0;
        _status = "";
        _busy = false;
    }

    public function setState(
        selected as Number,
        username as String,
        passwordLength as Number,
        status as String,
        busy as Boolean
    ) as Void {
        _selected = selected;
        _username = username;
        _passwordLength = passwordLength;
        _status = status;
        _busy = busy;

        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        dc.drawText(
            centerX,
            (height * 8) / 100,
            Graphics.FONT_MEDIUM,
            "LibreLinkUp",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            (height * 19) / 100,
            Graphics.FONT_XTINY,
            "Enter account credentials",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        var fieldWidth = (width * 76) / 100;
        var fieldHeight = (height * 10) / 100;

        if (fieldHeight < 30) {
            fieldHeight = 30;
        }

        drawField(
            dc,
            centerX,
            (height * 31) / 100,
            fieldWidth,
            fieldHeight,
            "USERNAME",
            getUsernameDisplay(),
            _selected == 0
        );

        drawField(
            dc,
            centerX,
            (height * 51) / 100,
            fieldWidth,
            fieldHeight,
            "PASSWORD",
            getPasswordDisplay(),
            _selected == 1
        );

        drawConnectButton(
            dc,
            centerX,
            (height * 70) / 100,
            fieldWidth,
            fieldHeight,
            _selected == 2
        );

        SafeText.drawBottom(dc, "UP/DOWN choose\nSELECT open");
    }

    private function drawField(
        dc as Graphics.Dc,
        centerX as Number,
        y as Number,
        width as Number,
        height as Number,
        label as String,
        value as String,
        selected as Boolean
    ) as Void {
        var x = centerX - width / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawText(
            centerX,
            y - 22,
            Graphics.FONT_XTINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(x, y, width, height);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawRectangle(x, y, width, height);
        }

        dc.drawText(
            centerX,
            y + 5,
            Graphics.FONT_SMALL,
            shorten(value, 24),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    private function drawConnectButton(
        dc as Graphics.Dc,
        centerX as Number,
        y as Number,
        width as Number,
        height as Number,
        selected as Boolean
    ) as Void {
        var x = centerX - width / 2;
        var text = _busy ? "CONNECTING..." : "CONNECT";

        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);

            dc.fillRectangle(x, y, width, height);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

            dc.drawRectangle(x, y, width, height);
        }

        dc.drawText(
            centerX,
            y + 5,
            Graphics.FONT_SMALL,
            text,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    private function getUsernameDisplay() as String {
        if (_username.length() == 0) {
            return "Enter username";
        }

        return _username;
    }

    private function getPasswordDisplay() as String {
        if (_passwordLength == 0) {
            return "Enter password";
        }

        var visibleLength = _passwordLength;
        var masked = "";

        if (visibleLength > 16) {
            visibleLength = 16;
        }

        for (var index = 0; index < visibleLength; index++) {
            masked += "*";
        }

        if (_passwordLength > visibleLength) {
            masked += "+";
        }

        return masked;
    }

    private function shorten(
        value as String,
        maximumLength as Number
    ) as String {
        if (value.length() <= maximumLength) {
            return value;
        }

        return value.substring(0, maximumLength - 3) + "...";
    }
}
