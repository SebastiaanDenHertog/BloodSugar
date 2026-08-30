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

module BloodSugarSharedSettings {
    const STORAGE_SETUP_DONE = "setupDone";
    const PROP_MONITOR = "bloodMonitorIndex";
    const PROP_USE_MGDL = "useMgdl";
    const PROP_NOTIFICATIONS_ENABLED = "notificationsEnabled";
    const PROP_NOTIFICATION_LOW = "notificationLow";
    const PROP_NOTIFICATION_HIGH = "notificationHigh";

    function getSetupDone() as Boolean {
        var value = BloodSugarSharedStorage.readValue(STORAGE_SETUP_DONE);
        return value instanceof Boolean ? value as Boolean : false;
    }

    function getMonitor() as Number {
        var value = BloodSugarSharedStorage.readProperty(PROP_MONITOR);
        return value instanceof Number ? value as Number : BloodSugarMonitor.NONE;
    }

    function getUseMgdl() as Boolean {
        return BloodSugarSharedStorage.readProperty(PROP_USE_MGDL) == true;
    }

    function getNotificationsEnabled() as Boolean {
        return BloodSugarSharedStorage.readProperty(
            PROP_NOTIFICATIONS_ENABLED
        ) != false;
    }

    function getNotificationLowMmol() as Float {
        return getRangeMmol(PROP_NOTIFICATION_LOW, 70.0f);
    }

    function getNotificationHighMmol() as Float {
        return getRangeMmol(PROP_NOTIFICATION_HIGH, 180.0f);
    }

    function mgdlToMmol(value as Float) as Float {
        return value / 18.018f;
    }

    function mmolToMgdl(value as Float) as Float {
        return value * 18.018f;
    }

    function formatValue(valueMmol as Float, useMgdl as Boolean) as String {
        return useMgdl
            ? mmolToMgdl(valueMmol).format("%.0f")
            : valueMmol.format("%.1f");
    }

    function getUnitText(useMgdl as Boolean) as String {
        return useMgdl ? "mg/dL" : "mmol/L";
    }

    function getRangeMmol(
        key as String,
        defaultMgdl as Float
    ) as Float {
        var value = BloodSugarSharedStorage.readProperty(key);
        if (value instanceof Float) {
            return mgdlToMmol(value as Float);
        }
        if (value instanceof Number) {
            return mgdlToMmol((value as Number).toFloat());
        }
        return mgdlToMmol(defaultMgdl);
    }
}
