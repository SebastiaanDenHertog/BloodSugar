import Toybox.System;
import Toybox.Lang;

module BloodSugarSystem {
    function isLowMemoryDevice() as Boolean {
        var stats = System.getSystemStats();
        return stats.totalMemory <= 131072;
    }

    function getMaximumHistoryPoints() as Number {
        if (isLowMemoryDevice()) {
            return 60;
        }

        return 240;
    }
}
