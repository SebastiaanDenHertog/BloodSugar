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

import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

module BloodSugarNotificationManager {
    const ALERT_NONE = 0;
    const ALERT_LOW = 1;
    const ALERT_HIGH = 2;
    const ALERT_COOLDOWN_SECONDS = 5 * 60;

    var _lastAlertType as Number = ALERT_NONE;
    var _lastAlertTimestamp as Number = 0;

    public function processReading(valueMmol as Float) as Number {
        if (!BloodSugarStore.getNotificationsEnabled()) {
            resetAlertState();
            return ALERT_NONE;
        }

        var alertType = getAlertType(valueMmol);

        if (alertType == ALERT_NONE) {
            resetAlertState();
            return ALERT_NONE;
        }

        if (!shouldSendAlert(alertType)) {
            return alertType;
        }

        sendAlert(alertType, valueMmol);

        _lastAlertType = alertType;
        _lastAlertTimestamp = System.getTimer() / 1000;

        return alertType;
    }

    public function getAlertType(valueMmol as Float) as Number {
        var lowThreshold = BloodSugarStore.getNotificationLowMmol();
        var highThreshold = BloodSugarStore.getNotificationHighMmol();
        if (valueMmol <= lowThreshold) {
            return ALERT_LOW;
        }
        if (valueMmol >= highThreshold) {
            return ALERT_HIGH;
        }
        return ALERT_NONE;
    }

    function shouldSendAlert(alertType as Number) as Boolean {
        if (_lastAlertType != alertType) {
            return true;
        }
        var currentTimestamp = System.getTimer() / 1000;
        var secondsSinceLastAlert = currentTimestamp - _lastAlertTimestamp;
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
        System.println("Low glucose alert: " + formatReading(valueMmol));
        vibrateLow();
    }

    function sendHighAlert(valueMmol as Float) as Void {
        System.println("High glucose alert: " + formatReading(valueMmol));
        vibrateHigh();
    }

    function vibrateLow() as Void {
        if (!(Attention has :vibrate)) {
            return;
        }
        var pattern = [
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 250),
            new Attention.VibeProfile(100, 500),
        ];
        Attention.vibrate(pattern);
    }

    function vibrateHigh() as Void {
        if (!(Attention has :vibrate)) {
            return;
        }
        var pattern = [
            new Attention.VibeProfile(75, 300),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(75, 300),
            new Attention.VibeProfile(0, 200),
            new Attention.VibeProfile(75, 300),
        ];

        Attention.vibrate(pattern);
    }

    function formatReading(valueMmol as Float) as String {
        return (
            BloodSugarStore.formatValue(
                valueMmol,
                BloodSugarStore.getUseMgdl()
            ) +
            " " +
            BloodSugarStore.getUnitText(BloodSugarStore.getUseMgdl())
        );
    }

    function resetAlertState() as Void {
        _lastAlertType = ALERT_NONE;
        _lastAlertTimestamp = 0;
    }
}
