import Toybox.System;
import Toybox.Lang;

module BloodSugarSystem {
    const COMPACT_PROFILE_MEMORY_LIMIT = 128 * 1024;

    function isLowMemoryDevice() as Boolean {
        var stats = System.getSystemStats();
        return stats.totalMemory <= COMPACT_PROFILE_MEMORY_LIMIT;
    }

    function usesCompactHistoryProfile() as Boolean {
        return isLowMemoryDevice();
    }

    function getMaximumHistoryPoints() as Number {
        if (usesCompactHistoryProfile()) {
            return 1500;
        }

        return 3200;
    }
}
