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
module BloodSugarMonitorRegistry {
    function createProvider(monitorId as Number) as BloodSugarSyncProvider? {
        if (monitorId == BloodSugarMonitor.ABBOTT_FREE_STYLE) {
            return new AbbottFreeStyleSyncProvider();
        }

        if (monitorId == BloodSugarMonitor.DEXCOM) {
            return new DexcomSyncProvider();
        }

        return null;
    }

    function hasMonitorSelected() as Boolean {
        return BloodSugarSharedSettings.getMonitor() != BloodSugarMonitor.NONE;
    }

    function isSelectedMonitorConfigured() as Boolean {
        if (!hasMonitorSelected()) {
            return false;
        }

        var provider = createProvider(BloodSugarSharedSettings.getMonitor());

        if (provider == null) {
            return false;
        }

        return provider.isConfigured();
    }

    function supportsBackgroundSync() as Boolean {
        if (!hasMonitorSelected()) {
            return false;
        }

        var monitorId = BloodSugarSharedSettings.getMonitor();
        if (
            monitorId == BloodSugarMonitor.ABBOTT_FREE_STYLE ||
            monitorId == BloodSugarMonitor.DEXCOM
        ) {
            return true;
        }
        return false;
    }

    function shouldUseBackgroundSync() as Boolean {
        if (!BloodSugarSharedSettings.getSetupDone()) {
            return false;
        }

        if (!supportsBackgroundSync()) {
            return false;
        }

        return isSelectedMonitorConfigured();
    }
}
