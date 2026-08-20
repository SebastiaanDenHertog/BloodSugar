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

class BloodSugarCharacterPickerFactory extends WatchUi.PickerFactory {
    private const DONE = -1;

    private var _characters as String;

    public function initialize(characters as String) {
        PickerFactory.initialize();
        _characters = characters;
    }

    public function getSize() as Number {
        return _characters.length() + 1;
    }

    public function getValue(index as Number) as Object? {
        if (index == _characters.length()) {
            return DONE;
        }
        return _characters.substring(index, index + 1);
    }

    public function getDrawable(
        index as Number,
        isSelected as Boolean
    ) as WatchUi.Drawable? {
        var label = "OK";
        if (index < _characters.length()) {
            var character = _characters.substring(index, index + 1);
            if (character != null) {
                label = character;
            }
        }

        return new WatchUi.Text({
            :text => label,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
        });
    }

    public function getIndex(character as String) as Number? {
        return _characters.find(character);
    }

    public function isDone(value) as Boolean {
        return value == DONE;
    }
}

class BloodSugarCharacterPicker extends WatchUi.Picker {
    private const CHARACTERS =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" +
        ",@._-+!#$%&*?:;\"'=()/[]{}<>";

    private var _text as String;
    private var _maximumLength as Number;
    private var _passwordMode as Boolean;
    private var _emptyTitle as String;
    private var _title as WatchUi.Text;
    private var _factory as BloodSugarCharacterPickerFactory;

    public function initialize(
        initialText as String,
        title as String,
        maximumLength as Number,
        allowSpace as Boolean,
        passwordMode as Boolean
    ) {
        _text = initialText;
        _maximumLength = maximumLength;
        _passwordMode = passwordMode;
        _emptyTitle = title;

        var characters = CHARACTERS;
        if (allowSpace) {
            characters += " ";
        }
        _factory = new BloodSugarCharacterPickerFactory(characters);

        _title = new WatchUi.Text({
            :text => getTitleText(title),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_XTINY,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
        });

        var options = {
            :title => _title,
            :pattern => [_factory],
        };

        if (_text.length() > 0) {
            var last = _text.substring(_text.length() - 1, _text.length());
            if (last != null) {
                var defaultIndex = _factory.getIndex(last);
                if (defaultIndex != null) {
                    options[:defaults] = [defaultIndex];
                }
            }
        }

        Picker.initialize(options);
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    public function appendCharacter(character as String) as Void {
        if (_text.length() >= _maximumLength) {
            return;
        }
        _text += character;
        _title.setText(getTitleText(_emptyTitle));
        WatchUi.requestUpdate();
    }

    public function deleteLastCharacter() as Boolean {
        if (_text.length() == 0) {
            return false;
        }
        var shortened = _text.substring(0, _text.length() - 1);
        if (shortened != null) {
            _text = shortened;
        }
        _title.setText(getTitleText(_emptyTitle));
        WatchUi.requestUpdate();
        return true;
    }

    public function getText() as String {
        return _text;
    }

    public function isDone(value) as Boolean {
        return _factory.isDone(value);
    }

    private function getTitleText(emptyTitle as String) as String {
        if (_text.length() == 0) {
            return emptyTitle;
        }
        if (_passwordMode) {
            var visibleLength = _text.length();
            if (visibleLength > 20) {
                visibleLength = 20;
            }
            var masked = "";
            for (var index = 0; index < visibleLength; index++) {
                masked += "*";
            }
            if (_text.length() > visibleLength) {
                masked += "+";
            }
            return masked;
        }
        if (_text.length() <= 20) {
            return _text;
        }
        var tail = _text.substring(_text.length() - 17, _text.length());
        return tail == null ? _text : "..." + tail;
    }
}

class BloodSugarCharacterPickerDelegate extends WatchUi.PickerDelegate {
    private var _picker as BloodSugarCharacterPicker;
    private var _parent as BloodSugarSetupApiDelegate;
    private var _field as Number;

    public function initialize(
        picker as BloodSugarCharacterPicker,
        parent as BloodSugarSetupApiDelegate,
        field as Number
    ) {
        PickerDelegate.initialize();
        _picker = picker;
        _parent = parent;
        _field = field;
    }

    public function onAccept(values as Array) as Boolean {
        var value = values[0];
        if (_picker.isDone(value)) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _parent.handleKeyboardCompleted(_field, _picker.getText());
            return true;
        }

        if (value instanceof String) {
            _picker.appendCharacter(value);
        }
        return true;
    }

    public function onCancel() as Boolean {
        if (!_picker.deleteLastCharacter()) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _parent.handleKeyboardCancelled();
        }
        return true;
    }
}
