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

(:background)
class AbbottFreeStyleSyncProvider extends BloodSugarSyncProvider {
    private var _api as AbbottFreeStyleApi?;
    private var _completion as BloodSugarSyncCallback?;

    public function initialize() {
        BloodSugarSyncProvider.initialize();

        _api = null;
        _completion = null;
    }

    public function getMonitorId() as Number {
        return BloodSugarMonitor.ABBOTT_FREE_STYLE;
    }

    public function isConfigured() as Boolean {
        return (
            BloodSugarApiStore.getUsername(getMonitorId()).length() > 0 &&
            BloodSugarApiStore.getPassword(getMonitorId()).length() > 0
        );
    }

    public function sync(completion as BloodSugarSyncCallback) as Void {
        _completion = completion;
        var username = BloodSugarApiStore.getUsername(getMonitorId());
        var password = BloodSugarApiStore.getPassword(getMonitorId());

        if (username.length() == 0 || password.length() == 0) {
            finishError("Abbott account is not configured");

            return;
        }

        _api = new AbbottFreeStyleApi(username, password);

        (_api as AbbottFreeStyleApi).read(method(:onApiReadComplete));
    }

    public function onApiReadComplete(
        success as Boolean,
        latestReadingTime as Number,
        latestValueMmol as Float,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        var result = new BloodSugarSyncResult(getMonitorId());
        result.success = success;
        result.addedCount = addedCount;
        result.errorMessage = errorMessage;

        if (success && latestReadingTime > 0 && latestValueMmol > 0) {
            result.latestReadingTime = latestReadingTime;

            result.latestValueMmol = latestValueMmol;
        }

        finish(result);
    }

    private function finishError(message as String) as Void {
        var result = new BloodSugarSyncResult(getMonitorId());
        result.success = false;
        result.errorMessage = message;
        finish(result);
    }

    private function finish(result as BloodSugarSyncResult) as Void {
        var completion = _completion;
        _completion = null;
        _api = null;

        if (completion != null) {
            completion.invoke(result);
        }
    }

    public function stop() as Void {
        if (_api != null) {
            (_api as AbbottFreeStyleApi).cancel();
        }

        _api = null;
        _completion = null;
    }
}
