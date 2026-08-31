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

import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarSettingsView extends WatchUi.Menu2 {
    private const INDEX_UNIT = 0;
    private const INDEX_ZONES = 1;
    private const INDEX_CONTEXT = 2;
    private const INDEX_CONFIRM = 3;
    private const INDEX_MONITOR = 4;
    private const INDEX_NOTIFICATIONS = 5;
    private const INDEX_NOTIFICATION_LOW = 6;
    private const INDEX_NOTIFICATION_HIGH = 7;
    private const INDEX_CLEAR = 8;

    private var _unitItem as WatchUi.ToggleMenuItem;
    private var _zonesItem as WatchUi.MenuItem;
    private var _contextItem as WatchUi.MenuItem;
    private var _confirmItem as WatchUi.ToggleMenuItem;
    private var _monitorItem as WatchUi.MenuItem;
    private var _notificationsItem as WatchUi.ToggleMenuItem;
    private var _notificationLowItem as WatchUi.MenuItem;
    private var _notificationHighItem as WatchUi.MenuItem;
    private var _clearItem as WatchUi.MenuItem;
    private var _clearStatus as String;

    public function initialize() {
        Menu2.initialize({:title => "Settings"});
        _clearStatus = "Cannot be undone";

        _unitItem = new WatchUi.ToggleMenuItem(
            "Display in mg/dL",
            {:enabled => "mg/dL", :disabled => "mmol/L"},
            :unit,
            BloodSugarStore.getUseMgdl(),
            null
        );
        _zonesItem = new WatchUi.MenuItem(
            "Glucose zones",
            "Edit thresholds",
            :zones,
            null
        );
        _contextItem = new WatchUi.MenuItem(
            "Default context",
            "",
            :context,
            null
        );
        _confirmItem = new WatchUi.ToggleMenuItem(
            "Confirm before save",
            {:enabled => "On", :disabled => "Off"},
            :confirm,
            BloodSugarStore.getConfirmBeforeSave(),
            null
        );
        _monitorItem = new WatchUi.MenuItem(
            "Monitor setup",
            "",
            :monitor,
            null
        );
        _notificationsItem = new WatchUi.ToggleMenuItem(
            "Notifications",
            {:enabled => "On", :disabled => "Off"},
            :notifications,
            BloodSugarStore.getNotificationsEnabled(),
            null
        );
        _notificationLowItem = new WatchUi.MenuItem(
            "Low notification",
            "",
            :notificationLow,
            null
        );
        _notificationHighItem = new WatchUi.MenuItem(
            "High notification",
            "",
            :notificationHigh,
            null
        );
        _clearItem = new WatchUi.MenuItem(
            "Delete all history",
            _clearStatus,
            :clear,
            null
        );

        addItem(_unitItem);
        addItem(_zonesItem);
        addItem(_contextItem);
        addItem(_confirmItem);
        addItem(_monitorItem);
        addItem(_notificationsItem);
        addItem(_notificationLowItem);
        addItem(_notificationHighItem);
        addItem(_clearItem);
        refresh();
    }

    public function onShow() as Void {
        refresh();
    }

    public function refresh() as Void {
        _unitItem.setEnabled(BloodSugarStore.getUseMgdl());
        _contextItem.setSubLabel(
            BloodSugarStore.getContextLabel(
                BloodSugarStore.getDefaultContextIndex()
            )
        );
        _confirmItem.setEnabled(BloodSugarStore.getConfirmBeforeSave());
        _monitorItem.setSubLabel(
            BloodSugarStore.getBloodMonitorText(
                BloodSugarStore.getBloodMonitor()
            )
        );
        _notificationsItem.setEnabled(
            BloodSugarStore.getNotificationsEnabled()
        );
        _notificationLowItem.setSubLabel(
            formatThreshold(BloodSugarStore.getNotificationLowMmol())
        );
        _notificationHighItem.setSubLabel(
            formatThreshold(BloodSugarStore.getNotificationHighMmol())
        );
        _clearItem.setSubLabel(_clearStatus);

        updateItem(_unitItem, INDEX_UNIT);
        updateItem(_zonesItem, INDEX_ZONES);
        updateItem(_contextItem, INDEX_CONTEXT);
        updateItem(_confirmItem, INDEX_CONFIRM);
        updateItem(_monitorItem, INDEX_MONITOR);
        updateItem(_notificationsItem, INDEX_NOTIFICATIONS);
        updateItem(_notificationLowItem, INDEX_NOTIFICATION_LOW);
        updateItem(_notificationHighItem, INDEX_NOTIFICATION_HIGH);
        updateItem(_clearItem, INDEX_CLEAR);
    }

    public function setClearStatus(status as String) as Void {
        _clearStatus = status;
        _clearItem.setSubLabel(status);
        updateItem(_clearItem, INDEX_CLEAR);
    }

    private function formatThreshold(valueMmol as Float) as String {
        var useMgdl = BloodSugarStore.getUseMgdl();
        return BloodSugarStore.formatValue(valueMmol, useMgdl)
            + " "
            + BloodSugarStore.getUnitText(useMgdl);
    }
}

class BloodSugarZonesView extends WatchUi.Menu2 {
    private var _dangerLowItem as WatchUi.MenuItem;
    private var _lowItem as WatchUi.MenuItem;
    private var _highItem as WatchUi.MenuItem;
    private var _dangerHighItem as WatchUi.MenuItem;

    public function initialize() {
        Menu2.initialize({:title => "Glucose zones"});
        _dangerLowItem = new WatchUi.MenuItem(
            "Danger low",
            "",
            :dangerLow,
            null
        );
        _lowItem = new WatchUi.MenuItem("Low limit", "", :low, null);
        _highItem = new WatchUi.MenuItem("High limit", "", :high, null);
        _dangerHighItem = new WatchUi.MenuItem(
            "Danger high",
            "",
            :dangerHigh,
            null
        );
        addItem(_dangerLowItem);
        addItem(_lowItem);
        addItem(_highItem);
        addItem(_dangerHighItem);
        refresh();
    }

    public function onShow() as Void {
        refresh();
    }

    public function refresh() as Void {
        _dangerLowItem.setSubLabel(
            formatThreshold(BloodSugarStore.getDangerLowMmol())
        );
        _lowItem.setSubLabel(formatThreshold(BloodSugarStore.getLowMmol()));
        _highItem.setSubLabel(formatThreshold(BloodSugarStore.getHighMmol()));
        _dangerHighItem.setSubLabel(
            formatThreshold(BloodSugarStore.getDangerHighMmol())
        );
        updateItem(_dangerLowItem, 0);
        updateItem(_lowItem, 1);
        updateItem(_highItem, 2);
        updateItem(_dangerHighItem, 3);
    }

    private function formatThreshold(valueMmol as Float) as String {
        var useMgdl = BloodSugarStore.getUseMgdl();
        return BloodSugarStore.formatValue(valueMmol, useMgdl)
            + " "
            + BloodSugarStore.getUnitText(useMgdl);
    }
}
