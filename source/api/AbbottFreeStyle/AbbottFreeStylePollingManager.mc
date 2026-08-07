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

import Toybox.Timer;
import Toybox.Lang;

class AbbottFreeStylePollingManager {
    const POLL_INTERVAL_MS = 60 * 1000;

    private var _timer as Timer.Timer?;
    private var _client as AbbottFreeStyleApi?;
    private var _requestRunning as Boolean = false;

    public function start() as Void {
        stop();
        _timer = new Timer.Timer();
        poll();

        (_timer as Timer.Timer).start(method(:poll), POLL_INTERVAL_MS, true);
    }

    public function stop() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        _client = null;
        _requestRunning = false;
    }

    private function poll() as Void {
        if (_requestRunning) {
            return;
        }
        var username = BloodSugarStore.getUsername();
        var password = BloodSugarStore.getPassword();
        if (username.length() == 0 || password.length() == 0) {
            return;
        }
        _requestRunning = true;
        var client = new AbbottFreeStyleApi(username, password);
        _client = client;
        client.read(method(:onReadComplete));
    }

    private function onReadComplete(
        success as Boolean,
        currentReading,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        _requestRunning = false;
        _client = null;

        if (!success) {
            System.println("Abbott polling error: " + errorMessage);

            return;
        }
        if (addedCount <= 0) {
            return;
        }
        if (currentReading == null) {
            return;
        }
        var valueMgdl = currentReading.ValueInMgPerDl;
        if (valueMgdl <= 0) {
            return;
        }
        var valueMmol = BloodSugarStore.MgdlToMoll(valueMgdl.toFloat());
        BloodSugarNotificationManager.processReading(valueMmol);
        WatchUi.requestUpdate();
    }
}
