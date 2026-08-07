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
class BloodSugarSyncManager {
    private var _provider as BloodSugarSyncProvider?;

    private var _completion;

    private var _syncing as Boolean;

    public function initialize() {
        _provider = null;
        _completion = null;
        _syncing = false;
    }

    public function isSyncing() as Boolean {
        return _syncing;
    }

    public function sync(completion) as Boolean {
        if (_syncing) {
            return false;
        }

        if (!BloodSugarMonitorRegistry.hasMonitorSelected()) {
            return false;
        }
        var monitorId = BloodSugarStore.getBloodMonitor();
        var provider = BloodSugarMonitorRegistry.createProvider(monitorId);
        if (provider == null) {
            return false;
        }

        if (!provider.isConfigured()) {
            return false;
        }

        _provider = provider;
        _completion = completion;
        _syncing = true;

        provider.sync(self.onProviderSyncComplete);

        return true;
    }

    private function onProviderSyncComplete(
        result as BloodSugarSyncResult
    ) as Void {
        if (
            result.success &&
            result.latestValueMmol != null &&
            result.latestReadingTime != null
        ) {
            BloodSugarNotificationManager.processReadingAt(
                result.latestValueMmol as Float,

                result.latestReadingTime as Number
            );
        }

        var completion = _completion;

        _completion = null;
        _syncing = false;

        if (_provider != null) {
            (_provider as BloodSugarSyncProvider).stop();
        }

        _provider = null;

        if (completion != null) {
            completion.invoke(result);
        }
    }

    public function stop() as Void {
        if (_provider != null) {
            (_provider as BloodSugarSyncProvider).stop();
        }

        _provider = null;
        _completion = null;
        _syncing = false;
    }
}
