/*
MIT License

Copyright (c) 2026 Sebastiaan den Hertog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarKeyboardView extends WatchUi.View {
    const ROW_COUNT = 4;

    private const BUTTON_PAGE_LOWER = 0;
    private const BUTTON_PAGE_UPPER = 1;
    private const BUTTON_PAGE_NUMBERS = 2;
    private const BUTTON_PAGE_SYMBOLS = 3;
    private const BUTTON_PAGE_ACTIONS = 4;
    private const BUTTON_PAGE_COUNT = 5;

    private const BUTTON_LOWER = "abcdefghijklmnopqrstuvwxyz";
    private const BUTTON_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private const BUTTON_NUMBERS = "0123456789";
    private const BUTTON_SYMBOLS = ",@._-+!#$%&*?:;\"'=()/[]{}<>";
    private const BUTTON_ACTIONS = ["DEL", "DONE", "CANCEL"];
    private const BUTTON_ACTIONS_WITH_SPACE = [
        "SPACE",
        "DEL",
        "DONE",
        "CANCEL",
    ];

    private const LETTER_ROW_0 = [
        "q",
        "w",
        "e",
        "r",
        "t",
        "y",
        "u",
        "i",
        "o",
        "p",
    ];
    private const LETTER_ROW_1 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"];
    private const LETTER_ROW_2 = [
        "SHIFT",
        "z",
        "x",
        "c",
        "v",
        "b",
        "n",
        "m",
        "DEL",
    ];
    private const NUMBER_ROW_0 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
    private const NUMBER_ROW_1 = ["!", "@", "#", "$", "%", "&", "*", "(", ")", "?"];
    private const NUMBER_ROW_2 = [":", ";", "\"", "'", "+", "=", "/", "DEL"];
    private const ACTION_ROW = ["PAGE", "@", ".", "_", "-", "CANCEL", "DONE"];

    private const WEIGHTS_TEN = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
    private const WEIGHTS_NINE = [10, 10, 10, 10, 10, 10, 10, 10, 10];
    private const WEIGHTS_LETTER_ROW_2 = [15, 10, 10, 10, 10, 10, 10, 10, 15];
    private const WEIGHTS_NUMBER_ROW_2 = [10, 10, 10, 10, 10, 10, 10, 15];
    private const WEIGHTS_ACTION_ROW = [15, 8, 8, 8, 8, 16, 15];

    private var _text as String;
    private var _passwordMode as Boolean;
    private var _title as String;
    private var _maximumLength as Number;
    private var _uppercase as Boolean;
    private var _numberPage as Boolean;
    private var _allowSpace as Boolean;
    private var _buttonMode as Boolean;
    private var _buttonPage as Number;
    private var _buttonIndex as Number;
    private var _width as Number;
    private var _height as Number;

    public function initialize(
        initialText as String,
        passwordMode as Boolean,
        title as String,
        maximumLength as Number,
        allowSpace as Boolean,
        buttonMode as Boolean
    ) {
        View.initialize();
        _text = initialText;
        _passwordMode = passwordMode;
        _title = title;
        _maximumLength = maximumLength;
        _uppercase = false;
        _numberPage = false;
        _allowSpace = allowSpace;
        _buttonMode = buttonMode;
        _buttonPage = BUTTON_PAGE_LOWER;
        _buttonIndex = 0;
        _width = 0;
        _height = 0;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        if (_buttonMode) {
            return;
        }
        setLayout(Rez.Layouts.BloodSugarKeyboardLayout(dc));
    }

    public function getText() as String {
        return _text;
    }

    public function isButtonMode() as Boolean {
        return _buttonMode;
    }

    public function selectPreviousButtonKey() as Void {
        _buttonIndex -= 1;
        if (_buttonIndex < 0) {
            _buttonIndex = getButtonKeyCount() - 1;
        }
        WatchUi.requestUpdate();
    }

    public function selectNextButtonKey() as Void {
        _buttonIndex += 1;
        if (_buttonIndex >= getButtonKeyCount()) {
            _buttonIndex = 0;
        }
        WatchUi.requestUpdate();
    }

    public function selectNextButtonPage() as Void {
        _buttonPage += 1;
        if (_buttonPage >= BUTTON_PAGE_COUNT) {
            _buttonPage = BUTTON_PAGE_LOWER;
        }
        _buttonIndex = 0;
        WatchUi.requestUpdate();
    }

    public function getSelectedButtonKey() as String {
        if (_buttonPage == BUTTON_PAGE_ACTIONS) {
            var actions = getButtonActions();
            return actions[_buttonIndex];
        }

        var characters = getButtonCharacters();
        var selected = characters.substring(_buttonIndex, _buttonIndex + 1);
        return selected == null ? "" : selected;
    }

    private function setLabel(id as String, value as String) as Void {
        var drawable = findDrawableById(id);
        if (drawable instanceof WatchUi.Text) {
            (drawable as WatchUi.Text).setText(value);
        }
    }

    public function toggleUppercase() as Void {
        _uppercase = !_uppercase;
        WatchUi.requestUpdate();
    }

    public function togglePage() as Void {
        _numberPage = !_numberPage;
        _uppercase = false;
        WatchUi.requestUpdate();
    }

    public function appendKey(key as String) as Void {
        var value = key;
        if (!_numberPage && _uppercase) {
            value = key.toUpper();
        }
        if (_text.length() + value.length() > _maximumLength) {
            return;
        }
        _text += value;
        WatchUi.requestUpdate();
    }

    public function deleteLastCharacter() as Void {
        var length = _text.length();
        if (length == 0) {
            return;
        }
        var shortened = _text.substring(0, length - 1);
        if (shortened != null) {
            _text = shortened;
        }
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (_buttonMode) {
            drawButtonKeyboard(dc);
            return;
        }
        drawInputField(dc);
        drawKeyboard(dc);
        setLabel("keyboardTitle", _title);
        setLabel("keyboardInput", getDisplayText());
        setLabel("keyboardCounter", _text.length() + "/" + _maximumLength);
        View.onUpdate(dc);
    }

    private function drawButtonKeyboard(dc as Graphics.Dc) as Void {
        var centerX = _width / 2;
        var selectedKey = getSelectedButtonKey();
        var selectedFont = selectedKey.length() == 1
            ? Graphics.FONT_LARGE
            : Graphics.FONT_SMALL;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            centerX,
            (_height * 4) / 100,
            Graphics.FONT_TINY,
            _title,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            (_height * 17) / 100,
            Graphics.FONT_XTINY,
            getDisplayText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawLine(
            (_width * 14) / 100,
            (_height * 31) / 100,
            (_width * 86) / 100,
            (_height * 31) / 100
        );
        dc.drawText(
            centerX,
            (_height * 35) / 100,
            selectedFont,
            getButtonKeyLabel(selectedKey),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            (_height * 54) / 100,
            Graphics.FONT_XTINY,
            getButtonPageLabel()
                + " "
                + (_buttonIndex + 1)
                + "/"
                + getButtonKeyCount(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            (_height * 65) / 100,
            Graphics.FONT_XTINY,
            "UP/DOWN: choose",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            (_height * 75) / 100,
            Graphics.FONT_XTINY,
            "SELECT: add/action",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            (_height * 85) / 100,
            Graphics.FONT_XTINY,
            "HOLD UP: next set",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function getButtonCharacters() as String {
        if (_buttonPage == BUTTON_PAGE_LOWER) {
            return BUTTON_LOWER;
        }
        if (_buttonPage == BUTTON_PAGE_UPPER) {
            return BUTTON_UPPER;
        }
        if (_buttonPage == BUTTON_PAGE_NUMBERS) {
            return BUTTON_NUMBERS;
        }
        return BUTTON_SYMBOLS;
    }

    private function getButtonActions() as Array<String> {
        if (_allowSpace) {
            return BUTTON_ACTIONS_WITH_SPACE as Array<String>;
        }
        return BUTTON_ACTIONS as Array<String>;
    }

    private function getButtonKeyCount() as Number {
        if (_buttonPage == BUTTON_PAGE_ACTIONS) {
            return getButtonActions().size();
        }
        return getButtonCharacters().length();
    }

    private function getButtonPageLabel() as String {
        if (_buttonPage == BUTTON_PAGE_LOWER) {
            return "abc";
        }
        if (_buttonPage == BUTTON_PAGE_UPPER) {
            return "ABC";
        }
        if (_buttonPage == BUTTON_PAGE_NUMBERS) {
            return "123";
        }
        if (_buttonPage == BUTTON_PAGE_SYMBOLS) {
            return "symbols";
        }
        return "actions";
    }

    private function getButtonKeyLabel(key as String) as String {
        if (key.equals("SPACE")) {
            return "space";
        }
        if (key.equals("DEL")) {
            return "delete";
        }
        if (key.equals("DONE")) {
            return "done";
        }
        if (key.equals("CANCEL")) {
            return "cancel";
        }
        return key;
    }

    public function getKeyAt(tapX as Number, tapY as Number) as String? {
        if (_width <= 0 || _height <= 0) {
            return null;
        }
        var keyboardTop = getKeyboardTop();
        var keyboardBottom = getKeyboardBottom();
        if (tapY < keyboardTop || tapY >= keyboardBottom) {
            return null;
        }
        var rowHeight = (keyboardBottom - keyboardTop) / ROW_COUNT;
        for (var row = 0; row < ROW_COUNT; row += 1) {
            var rowY = keyboardTop + row * rowHeight;
            var keyY = rowY + 2;
            var keyHeight = rowHeight - 4;
            if (tapY < keyY || tapY >= keyY + keyHeight) {
                continue;
            }
            var keys = getRowKeys(row);
            var weights = getRowWeights(row);
            var rowWidth = getRowWidth(row);
            var rowX = (_width - rowWidth) / 2;
            var gap = getHorizontalGap();
            var totalWeight = getTotalWeight(weights);
            var usableWidth = rowWidth - gap * (keys.size() - 1);
            var currentX = rowX;
            for (var index = 0; index < keys.size(); index += 1) {
                var keyWidth;
                if (index == keys.size() - 1) {
                    keyWidth = rowX + rowWidth - currentX;
                } else {
                    keyWidth = (usableWidth * weights[index]) / totalWeight;
                }
                if (tapX >= currentX && tapX < currentX + keyWidth) {
                    return keys[index];
                }
                currentX += keyWidth + gap;
            }
        }
        return null;
    }
    private function drawInputField(dc as Graphics.Dc) as Void {
        var centerX = _width / 2;
        var fieldWidth = (_width * 76) / 100;
        var fieldHeight = (_height * 13) / 100;
        var fieldX = centerX - fieldWidth / 2;
        var fieldY = (_height * 17) / 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawRectangle(fieldX, fieldY, fieldWidth, fieldHeight);
    }

    private function drawKeyboard(dc as Graphics.Dc) as Void {
        var keyboardTop = getKeyboardTop();
        var keyboardBottom = getKeyboardBottom();
        var rowHeight = (keyboardBottom - keyboardTop) / ROW_COUNT;
        for (var row = 0; row < ROW_COUNT; row += 1) {
            var keys = getRowKeys(row);
            var weights = getRowWeights(row);
            var rowWidth = getRowWidth(row);
            var rowX = (_width - rowWidth) / 2;
            var rowY = keyboardTop + row * rowHeight;
            var keyY = rowY + 2;
            var keyHeight = rowHeight - 4;
            var gap = getHorizontalGap();
            var totalWeight = getTotalWeight(weights);
            var usableWidth = rowWidth - gap * (keys.size() - 1);
            var currentX = rowX;
            for (var index = 0; index < keys.size(); index += 1) {
                var keyWidth;
                if (index == keys.size() - 1) {
                    keyWidth = rowX + rowWidth - currentX;
                } else {
                    keyWidth = (usableWidth * weights[index]) / totalWeight;
                }
                drawKey(dc, currentX, keyY, keyWidth, keyHeight, keys[index]);
                currentX += keyWidth + gap;
            }
        }
    }

    private function drawKey(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        width as Number,
        height as Number,
        key as String
    ) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawRectangle(x, y, width, height);
        var label = getKeyLabel(key);
        var font = Graphics.FONT_XTINY;
        var textY = y + (height - dc.getFontHeight(font)) / 2;
        dc.drawText(
            x + width / 2,
            textY,
            font,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function getDisplayText() as String {
        if (_text.length() == 0) {
            return _passwordMode ? "Enter password" : "Enter username";
        }

        var visibleLength = _buttonMode ? 16 : 24;
        var tailLength = _buttonMode ? 13 : 21;
        if (_text.length() <= visibleLength) {
            return _text;
        }
        var tail = _text.substring(_text.length() - tailLength, _text.length());
        if (tail == null) {
            return _text;
        }
        return "..." + tail;
    }

    private function getKeyLabel(key as String) as String {
        if (key.equals("SHIFT")) {
            return _uppercase ? "abc" : "CAPS";
        }
        if (key.equals("PAGE")) {
            return _numberPage ? "ABC" : "123";
        }
        if (key.equals("DEL") || key.equals("DONE") || key.equals("CANCEL")) {
            return key;
        }
        if (!_numberPage && _uppercase) {
            return key.toUpper();
        }
        return key;
    }

    private function getRowKeys(row as Number) as Array<String> {
        if (_numberPage) {
            return getNumberRowKeys(row);
        }
        return getLetterRowKeys(row);
    }

    private function getLetterRowKeys(row as Number) as Array<String> {
        if (row == 0) {
            return LETTER_ROW_0 as Array<String>;
        }

        if (row == 1) {
            return LETTER_ROW_1 as Array<String>;
        }

        if (row == 2) {
            return LETTER_ROW_2 as Array<String>;
        }

        return ACTION_ROW as Array<String>;
    }

    private function getNumberRowKeys(row as Number) as Array<String> {
        if (row == 0) {
            return NUMBER_ROW_0 as Array<String>;
        }

        if (row == 1) {
            return NUMBER_ROW_1 as Array<String>;
        }

        if (row == 2) {
            return NUMBER_ROW_2 as Array<String>;
        }

        return ACTION_ROW as Array<String>;
    }

    private function getRowWeights(row as Number) as Array<Number> {
        if (row == 0) {
            return WEIGHTS_TEN as Array<Number>;
        }
        if (row == 1) {
            if (_numberPage) {
                return WEIGHTS_TEN as Array<Number>;
            }
            return WEIGHTS_NINE as Array<Number>;
        }
        if (row == 2) {
            if (_numberPage) {
                return WEIGHTS_NUMBER_ROW_2 as Array<Number>;
            }
            return WEIGHTS_LETTER_ROW_2 as Array<Number>;
        }
        return WEIGHTS_ACTION_ROW as Array<Number>;
    }

    private function getTotalWeight(weights as Array<Number>) as Number {
        var total = 0;
        for (var index = 0; index < weights.size(); index += 1) {
            total += weights[index];
        }
        return total;
    }

    private function getKeyboardTop() as Number {
        return (_height * 39) / 100;
    }

    private function getKeyboardBottom() as Number {
        return (_height * 92) / 100;
    }

    private function getHorizontalGap() as Number {
        var gap = _width / 120;
        if (gap < 2) {
            gap = 2;
        }
        return gap;
    }

    private function getRowWidth(row as Number) as Number {
        if (row == 0) {
            return (_width * 94) / 100;
        }
        if (row == 1) {
            return (_width * 92) / 100;
        }
        if (row == 2) {
            return (_width * 84) / 100;
        }
        return (_width * 70) / 100;
    }
}
