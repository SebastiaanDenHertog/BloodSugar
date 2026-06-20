//
// Copyright 2019-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.BluetoothLowEnergy;

class ProfileManager {

    public const BloodSugar_SERVICE_UUID         = BluetoothLowEnergy.longToUuid(0xEF6805009B354933L, 0x9B1052FFA9740042L);
    public const BloodSugar_MEASUREMENT_UUID  = BluetoothLowEnergy.longToUuid(0xEF6805019B354933L, 0x9B1052FFA9740042L);
    public const CLIENT_CHARACTERISTIC_CONFIGURATION_UUID  = BluetoothLowEnergy.longToUuid(0xEF6805029B354933L, 0x9B1052FFA9740042L);

    
    private const _BloodSugarProfile = {
        :uuid => BloodSugar_SERVICE_UUID,

        :characteristics => [{
            :uuid => BloodSugar_MEASUREMENT_UUID,
            :descriptors => [
                CLIENT_CHARACTERISTIC_CONFIGURATION_UUID
            ]
        }]
    };

    //! Register the bluetooth profile
    public function registerProfiles() as Void {
       BluetoothLowEnergy.registerProfile(_BloodSugarProfile);
    }
}
