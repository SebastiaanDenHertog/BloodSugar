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

import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

class xDripPollingManager {
    const POLL_INTERVAL_MS = 60 * 1000;

    private var _timer as Timer.Timer?;
    private var _client as xDripApi?;
    private var _requestRunning as Boolean;

    public function initialize() {
        _timer = null;
        _client = null;
        _requestRunning = false;
    }

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

        if (_client != null) {
            (_client as xDripApi).cancel();
        }

        _client = null;
        _requestRunning = false;
    }

    public function poll() as Void {
        if (_requestRunning) {
            return;
        }

        if (_client == null) {
            var server = BloodSugarApiStore.getServer(
                BloodSugarMonitor.XDRIP,
                "",
                xDripShareConfig.DEFAULT_SERVER
            );
            _client = new xDripApi(server);
        }

        _requestRunning = true;

        (_client as xDripApi).read(method(:onReadComplete));
    }

    public function onReadComplete(
        success as Boolean,
        latestReadingTime as Number,
        latestValueMmol as Float,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        _requestRunning = false;

        if (!success) {
            System.println("Xdrip polling error: " + errorMessage);
            return;
        }

        if (addedCount <= 0 || latestReadingTime <= 0 || latestValueMmol <= 0) {
            return;
        }

        BloodSugarNotificationManager.processReading(latestValueMmol);
        WatchUi.requestUpdate();
    }
}
