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
    private var _text as String;
    private var _passwordMode as Boolean;
    private var _title as String;
    private var _maximumLength as Number;
    private var _uppercase as Boolean;
    private var _numberPage as Boolean;
    private var _width as Number;
    private var _height as Number;

    public function initialize(
        initialText as String,
        passwordMode as Boolean,
        title as String,
        maximumLength as Number,
        allowSpace as Boolean
    ) {
        View.initialize();
        _text = initialText;
        _passwordMode = passwordMode;
        _title = title;
        _maximumLength = maximumLength;
        _uppercase = false;
        _numberPage = false;
        _width = 0;
        _height = 0;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.BloodSugarKeyboardLayout(dc));
    }

    public function getText() as String {
        return _text;
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
        drawInputField(dc);
        drawKeyboard(dc);
        setLabel("keyboardTitle", _title);
        setLabel("keyboardInput", getDisplayText());
        setLabel("keyboardCounter", _text.length() + "/" + _maximumLength);
        View.onUpdate(dc);
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

        if (_text.length() <= 24) {
            return _text;
        }
        var tail = _text.substring(_text.length() - 21, _text.length());
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
            return (
                ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"] as
                Array<String>
            );
        }

        if (row == 1) {
            return (
                ["a", "s", "d", "f", "g", "h", "j", "k", "l"] as Array<String>
            );
        }

        if (row == 2) {
            return (
                ["SHIFT", "z", "x", "c", "v", "b", "n", "m", "DEL"] as
                Array<String>
            );
        }

        return ["PAGE", "@", ".", "_", "-", "CANCEL", "DONE"] as Array<String>;
    }

    private function getNumberRowKeys(row as Number) as Array<String> {
        if (row == 0) {
            return (
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] as
                Array<String>
            );
        }

        if (row == 1) {
            return (
                ["!", "@", "#", "$", "%", "&", "*", "(", ")", "?"] as
                Array<String>
            );
        }

        if (row == 2) {
            return [":", ";", "\"", "'", "+", "=", "/", "DEL"] as Array<String>;
        }

        return ["PAGE", "@", ".", "_", "-", "CANCEL", "DONE"] as Array<String>;
    }

    private function getRowWeights(row as Number) as Array<Number> {
        if (row == 0) {
            return [10, 10, 10, 10, 10, 10, 10, 10, 10, 10] as Array<Number>;
        }
        if (row == 1) {
            if (_numberPage) {
                return (
                    [10, 10, 10, 10, 10, 10, 10, 10, 10, 10] as Array<Number>
                );
            }
            return [10, 10, 10, 10, 10, 10, 10, 10, 10] as Array<Number>;
        }
        if (row == 2) {
            if (_numberPage) {
                return [10, 10, 10, 10, 10, 10, 10, 15] as Array<Number>;
            }
            return [15, 10, 10, 10, 10, 10, 10, 10, 15] as Array<Number>;
        }
        return [15, 8, 8, 8, 8, 16, 15] as Array<Number>;
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
