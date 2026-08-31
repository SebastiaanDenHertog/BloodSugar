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

import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Notifications;
import Toybox.System;
import Toybox.Time;

(:background)
module BloodSugarNotificationManager {
    const ALERT_NONE = 0;
    const ALERT_LOW = 1;
    const ALERT_HIGH = 2;

    const ALERT_COOLDOWN_SECONDS = 5 * 60;

    const STORAGE_LAST_ALERT_TYPE = "notificationLastAlertType";
    const STORAGE_LAST_ALERT_TIME = "notificationLastAlertTime";
    const STORAGE_LAST_READING_TIME = "notificationLastReadingTime";

    public function processReading(valueMmol as Float) as Number {
        return processReadingAt(valueMmol, Time.now().value());
    }

    public function processReadingAt(
        valueMmol as Float,
        readingTimestamp as Number
    ) as Number {
        if (valueMmol <= 0.0f || readingTimestamp <= 0) {
            return ALERT_NONE;
        }

        var lastReadingTimestamp = getStoredNumber(
            STORAGE_LAST_READING_TIME,
            0
        );

        if (readingTimestamp <= lastReadingTimestamp) {
            return getStoredNumber(STORAGE_LAST_ALERT_TYPE, ALERT_NONE);
        }

        saveNumber(STORAGE_LAST_READING_TIME, readingTimestamp);

        if (!BloodSugarSharedSettings.getNotificationsEnabled()) {
            clearActiveAlert();

            return ALERT_NONE;
        }

        var alertType = getAlertType(valueMmol);

        if (alertType == ALERT_NONE) {
            clearActiveAlert();

            return ALERT_NONE;
        }

        if (!shouldSendAlert(alertType)) {
            return alertType;
        }

        sendAlert(alertType, valueMmol);
        saveNumber(STORAGE_LAST_ALERT_TYPE, alertType);
        saveNumber(STORAGE_LAST_ALERT_TIME, Time.now().value());
        return alertType;
    }

    public function getAlertType(valueMmol as Float) as Number {
        var lowThreshold = BloodSugarSharedSettings.getNotificationLowMmol();
        var highThreshold = BloodSugarSharedSettings.getNotificationHighMmol();

        if (valueMmol <= lowThreshold) {
            return ALERT_LOW;
        }

        if (valueMmol >= highThreshold) {
            return ALERT_HIGH;
        }

        return ALERT_NONE;
    }

    function shouldSendAlert(alertType as Number) as Boolean {
        var lastAlertType = getStoredNumber(
            STORAGE_LAST_ALERT_TYPE,
            ALERT_NONE
        );

        if (lastAlertType != alertType) {
            return true;
        }

        var lastAlertTimestamp = getStoredNumber(STORAGE_LAST_ALERT_TIME, 0);

        if (lastAlertTimestamp <= 0) {
            return true;
        }

        var currentTimestamp = Time.now().value();
        var secondsSinceLastAlert = currentTimestamp - lastAlertTimestamp;

        if (secondsSinceLastAlert < 0) {
            return true;
        }

        return secondsSinceLastAlert >= ALERT_COOLDOWN_SECONDS;
    }

    function sendAlert(alertType as Number, valueMmol as Float) as Void {
        if (alertType == ALERT_LOW) {
            sendLowAlert(valueMmol);
            return;
        }

        if (alertType == ALERT_HIGH) {
            sendHighAlert(valueMmol);
        }
    }

    function sendLowAlert(valueMmol as Float) as Void {
        var reading = formatReading(valueMmol);
        System.println("Low glucose alert: " + reading);
        showSystemNotification("Low glucose", reading);
    }

    function sendHighAlert(valueMmol as Float) as Void {
        var reading = formatReading(valueMmol);
        System.println("High glucose alert: " + reading);
        showSystemNotification("High glucose", reading);
    }

    function showSystemNotification(
        title as String,
        reading as String
    ) as Void {
        if (!(Toybox has :Notifications)) {
            System.println("Notifications API is not available");
            return;
        }

        try {
            Notifications.showNotification(title, reading, {
                :body => "Blood Sugar Logger",

                :dismissPrevious => true,
            });
        } catch (error) {
            System.println("Could not show glucose notification");
        }
    }

    function formatReading(valueMmol as Float) as String {
        var useMgdl = BloodSugarSharedSettings.getUseMgdl();

        return (
            BloodSugarSharedSettings.formatValue(valueMmol, useMgdl) +
            " " +
            BloodSugarSharedSettings.getUnitText(useMgdl)
        );
    }

    function clearActiveAlert() as Void {
        saveNumber(STORAGE_LAST_ALERT_TYPE, ALERT_NONE);

        saveNumber(STORAGE_LAST_ALERT_TIME, 0);
    }

    function getStoredNumber(key as String, defaultValue as Number) as Number {
        try {
            var value = BloodSugarSharedStorage.readValue(key);

            if (value instanceof Lang.Number) {
                return value as Number;
            }
        } catch (error) {
            System.println("Could not read notification state");
        }

        return defaultValue;
    }

    function saveNumber(key as String, value as Number) as Void {
        try {
            BloodSugarSharedStorage.writeValue(key, value);
        } catch (error) {
            System.println("Could not save notification state");
        }
    }

    public function resetAlertState() as Void {
        try {
            Storage.deleteValue(STORAGE_LAST_ALERT_TYPE);

            Storage.deleteValue(STORAGE_LAST_ALERT_TIME);

            Storage.deleteValue(STORAGE_LAST_READING_TIME);
        } catch (error) {
            System.println("Could not reset notification state");
        }
    }
}
