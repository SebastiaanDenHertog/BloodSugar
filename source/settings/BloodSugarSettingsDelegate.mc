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

module BloodSugarThresholdKind {
    const DANGER_LOW = 0;
    const LOW = 1;
    const HIGH = 2;
    const DANGER_HIGH = 3;
    const NOTIFICATION_LOW = 4;
    const NOTIFICATION_HIGH = 5;
}

class BloodSugarSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as BloodSugarSettingsView;

    public function initialize(view as BloodSugarSettingsView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :unit && item instanceof WatchUi.ToggleMenuItem) {
            BloodSugarStore.setUseMgdl(
                (item as WatchUi.ToggleMenuItem).isEnabled()
            );
            _view.refresh();
            return;
        }
        if (id == :confirm && item instanceof WatchUi.ToggleMenuItem) {
            BloodSugarStore.setConfirmBeforeSave(
                (item as WatchUi.ToggleMenuItem).isEnabled()
            );
            return;
        }
        if (id == :notifications && item instanceof WatchUi.ToggleMenuItem) {
            BloodSugarStore.setNotificationsEnabled(
                (item as WatchUi.ToggleMenuItem).isEnabled()
            );
            return;
        }
        if (id == :zones) {
            var zonesView = new BloodSugarZonesView();
            WatchUi.pushView(
                zonesView,
                new BloodSugarZonesDelegate(),
                WatchUi.SLIDE_LEFT
            );
            return;
        }
        if (id == :context) {
            openContextPicker();
            return;
        }
        if (id == :monitor) {
            var monitorView = new BloodSugarSetupMonitorView();
            WatchUi.pushView(
                monitorView,
                new BloodSugarSetupMonitorDelegate(monitorView),
                WatchUi.SLIDE_LEFT
            );
            return;
        }
        if (id == :notificationLow) {
            openThresholdPicker(BloodSugarThresholdKind.NOTIFICATION_LOW);
            return;
        }
        if (id == :notificationHigh) {
            openThresholdPicker(BloodSugarThresholdKind.NOTIFICATION_HIGH);
            return;
        }
        if (id == :clear) {
            var confirmation = new WatchUi.Confirmation("Delete all history?");
            WatchUi.pushView(
                confirmation,
                new BloodSugarClearConfirmationDelegate(self),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    public function handleClearResponse(confirm as Boolean) as Void {
        if (!confirm) {
            return;
        }
        if (BloodSugarStore.clear()) {
            _view.setClearStatus("History deleted");
        } else {
            _view.setClearStatus("Could not delete history");
        }
    }

    private function openContextPicker() as Void {
        var labels = [] as Array<String>;
        for (
            var index = 0;
            index < BloodSugarStore.getContextCount();
            index++
        ) {
            labels.add(BloodSugarStore.getContextLabel(index));
        }
        var picker = new BloodSugarSelectionPicker(
            "Default context",
            labels,
            BloodSugarStore.getDefaultContextIndex()
        );
        WatchUi.pushView(
            picker,
            new BloodSugarContextPickerDelegate(),
            WatchUi.SLIDE_UP
        );
    }

    private function openThresholdPicker(kind as Number) as Void {
        var range = BloodSugarThresholdRange.get(kind);
        var picker = new BloodSugarThresholdPicker(
            range.title,
            range.minimum,
            range.maximum,
            range.current,
            range.useMgdl
        );
        WatchUi.pushView(
            picker,
            new BloodSugarThresholdPickerDelegate(kind, range.useMgdl),
            WatchUi.SLIDE_UP
        );
    }
}

class BloodSugarZonesDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var kind = BloodSugarThresholdKind.DANGER_LOW;
        if (id == :low) {
            kind = BloodSugarThresholdKind.LOW;
        } else if (id == :high) {
            kind = BloodSugarThresholdKind.HIGH;
        } else if (id == :dangerHigh) {
            kind = BloodSugarThresholdKind.DANGER_HIGH;
        }

        var range = BloodSugarThresholdRange.get(kind);
        var picker = new BloodSugarThresholdPicker(
            range.title,
            range.minimum,
            range.maximum,
            range.current,
            range.useMgdl
        );
        WatchUi.pushView(
            picker,
            new BloodSugarThresholdPickerDelegate(kind, range.useMgdl),
            WatchUi.SLIDE_UP
        );
    }
}

class BloodSugarThresholdRange {
    public var title as String;
    public var minimum as Number;
    public var maximum as Number;
    public var current as Number;
    public var useMgdl as Boolean;

    public function initialize(
        titleText as String,
        minimumValue as Number,
        maximumValue as Number,
        currentValue as Number,
        useMgdlValue as Boolean
    ) {
        title = titleText;
        minimum = minimumValue;
        maximum = maximumValue;
        current = currentValue;
        useMgdl = useMgdlValue;
    }

    public static function get(kind as Number) as BloodSugarThresholdRange {
        var useMgdl = BloodSugarStore.getUseMgdl();
        var step = 1;
        var maximum = toScaled(50.0f, useMgdl);
        var minimum = step;
        var current = step;
        var title = "Threshold";

        if (kind == BloodSugarThresholdKind.DANGER_LOW) {
            title = "Danger low";
            current = toScaled(BloodSugarStore.getDangerLowMmol(), useMgdl);
            maximum = toScaled(BloodSugarStore.getLowMmol(), useMgdl) - step;
        } else if (kind == BloodSugarThresholdKind.LOW) {
            title = "Low limit";
            minimum = toScaled(
                BloodSugarStore.getDangerLowMmol(),
                useMgdl
            ) + step;
            current = toScaled(BloodSugarStore.getLowMmol(), useMgdl);
            maximum = toScaled(BloodSugarStore.getHighMmol(), useMgdl) - step;
        } else if (kind == BloodSugarThresholdKind.HIGH) {
            title = "High limit";
            minimum = toScaled(BloodSugarStore.getLowMmol(), useMgdl) + step;
            current = toScaled(BloodSugarStore.getHighMmol(), useMgdl);
            maximum = toScaled(
                BloodSugarStore.getDangerHighMmol(),
                useMgdl
            ) - step;
        } else if (kind == BloodSugarThresholdKind.DANGER_HIGH) {
            title = "Danger high";
            minimum = toScaled(BloodSugarStore.getHighMmol(), useMgdl) + step;
            current = toScaled(
                BloodSugarStore.getDangerHighMmol(),
                useMgdl
            );
        } else if (kind == BloodSugarThresholdKind.NOTIFICATION_LOW) {
            title = "Low notification";
            current = toScaled(
                BloodSugarStore.getNotificationLowMmol(),
                useMgdl
            );
            maximum = toScaled(
                BloodSugarStore.getNotificationHighMmol(),
                useMgdl
            ) - step;
        } else {
            title = "High notification";
            minimum = toScaled(
                BloodSugarStore.getNotificationLowMmol(),
                useMgdl
            ) + step;
            current = toScaled(
                BloodSugarStore.getNotificationHighMmol(),
                useMgdl
            );
        }

        if (maximum < minimum) {
            maximum = minimum;
        }
        if (current < minimum) {
            current = minimum;
        } else if (current > maximum) {
            current = maximum;
        }
        return new BloodSugarThresholdRange(
            title,
            minimum,
            maximum,
            current,
            useMgdl
        );
    }

    public static function toScaled(
        valueMmol as Float,
        useMgdl as Boolean
    ) as Number {
        if (useMgdl) {
            return (BloodSugarStore.MollToMgdl(valueMmol) + 0.5f).toNumber();
        }
        return (valueMmol * 10.0f + 0.5f).toNumber();
    }

    public static function fromScaled(
        value as Number,
        useMgdl as Boolean
    ) as Float {
        if (useMgdl) {
            return BloodSugarStore.MgdlToMoll(value.toFloat());
        }
        return value.toFloat() / 10.0f;
    }
}

class BloodSugarThresholdPickerFactory extends WatchUi.PickerFactory {
    private var _minimum as Number;
    private var _maximum as Number;
    private var _useMgdl as Boolean;

    public function initialize(
        minimum as Number,
        maximum as Number,
        useMgdl as Boolean
    ) {
        PickerFactory.initialize();
        _minimum = minimum;
        _maximum = maximum;
        _useMgdl = useMgdl;
    }

    public function getSize() as Number {
        return _maximum - _minimum + 1;
    }

    public function getValue(index as Number) as Object? {
        return _minimum + index;
    }

    public function getDrawable(
        index as Number,
        selected as Boolean
    ) as WatchUi.Drawable? {
        var value = _minimum + index;
        var label = _useMgdl
            ? value.format("%d") + " mg/dL"
            : (value.toFloat() / 10.0f).format("%.1f") + " mmol/L";
        return new WatchUi.Text({
            :text => label,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
        });
    }
}

class BloodSugarThresholdPicker extends WatchUi.Picker {
    public function initialize(
        titleText as String,
        minimum as Number,
        maximum as Number,
        current as Number,
        useMgdl as Boolean
    ) {
        var title = new WatchUi.Text({
            :text => titleText,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_XTINY,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
        });
        var factory = new BloodSugarThresholdPickerFactory(
            minimum,
            maximum,
            useMgdl
        );
        Picker.initialize({
            :title => title,
            :pattern => [factory],
            :defaults => [current - minimum],
        });
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}

class BloodSugarThresholdPickerDelegate extends WatchUi.PickerDelegate {
    private var _kind as Number;
    private var _useMgdl as Boolean;

    public function initialize(kind as Number, useMgdl as Boolean) {
        PickerDelegate.initialize();
        _kind = kind;
        _useMgdl = useMgdl;
    }

    public function onAccept(values as Array) as Boolean {
        var selected = values[0];
        if (!(selected instanceof Number)) {
            return false;
        }
        var value = BloodSugarThresholdRange.fromScaled(
            selected as Number,
            _useMgdl
        );
        if (_kind == BloodSugarThresholdKind.DANGER_LOW) {
            BloodSugarStore.setDangerLowMmol(value);
        } else if (_kind == BloodSugarThresholdKind.LOW) {
            BloodSugarStore.setLowMmol(value);
        } else if (_kind == BloodSugarThresholdKind.HIGH) {
            BloodSugarStore.setHighMmol(value);
        } else if (_kind == BloodSugarThresholdKind.DANGER_HIGH) {
            BloodSugarStore.setDangerHighMmol(value);
        } else if (_kind == BloodSugarThresholdKind.NOTIFICATION_LOW) {
            BloodSugarStore.setNotificationLowMmol(value);
        } else {
            BloodSugarStore.setNotificationHighMmol(value);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

class BloodSugarContextPickerDelegate extends WatchUi.PickerDelegate {
    public function initialize() {
        PickerDelegate.initialize();
    }

    public function onAccept(values as Array) as Boolean {
        var selected = values[0];
        if (!(selected instanceof Number)) {
            return false;
        }
        BloodSugarStore.setDefaultContextIndex(selected as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

class BloodSugarClearConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var _parent as BloodSugarSettingsDelegate;

    public function initialize(parent as BloodSugarSettingsDelegate) {
        ConfirmationDelegate.initialize();
        _parent = parent;
    }

    public function onResponse(response as WatchUi.Confirm) as Boolean {
        _parent.handleClearResponse(response == WatchUi.CONFIRM_YES);
        return true;
    }
}
