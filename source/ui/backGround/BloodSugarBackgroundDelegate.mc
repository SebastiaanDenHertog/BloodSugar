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

import Toybox.Background;
import Toybox.System;
import Toybox.Lang;

(:background)
class BloodSugarBackgroundDelegate extends System.ServiceDelegate {
    private var _syncManager as BloodSugarSyncManager?;

    public function initialize() {
        ServiceDelegate.initialize();

        _syncManager = null;
    }

    public function onTemporalEvent() as Void {
        if (!BloodSugarMonitorRegistry.shouldUseBackgroundSync()) {
            Background.exit(null);
            return;
        }

        _syncManager = new BloodSugarSyncManager();

        var started = (_syncManager as BloodSugarSyncManager).sync(
            self.onSyncComplete
        );

        if (!started) {
            Background.exit(null);
        }
    }

    private function onSyncComplete(
        result as BloodSugarSyncResult,
        notificationShown as Boolean
    ) as Void {
        Background.exit({
            "success" => result.success,
            "added" => result.addedCount,
            "monitor" => result.monitorId,
            "notification" => notificationShown,
        });
    }
}
