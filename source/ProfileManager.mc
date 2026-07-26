import Toybox.BluetoothLowEnergy;
import Toybox.System;
import Toybox.Lang;

class ProfileManager {
    public const BloodSugar_SERVICE_UUID = BluetoothLowEnergy.longToUuid(
        0xef6805009b354933l,
        0x9b1052ffa9740042l
    );

    public const BloodSugar_MEASUREMENT_UUID = BluetoothLowEnergy.longToUuid(
        0xef6805019b354933l,
        0x9b1052ffa9740042l
    );

    private static var _registrationRequested as Boolean = false;

    private var _profileReady as Boolean = false;

    public function initialize() {}

    public function registerProfiles() as Void {
        if (_registrationRequested) {
            return;
        }

        _registrationRequested = true;

        try {
            BluetoothLowEnergy.registerProfile(createProfile());
        } catch (exception instanceof
            BluetoothLowEnergy.ProfileRegistrationException) {
            _registrationRequested = false;

            exception.printStackTrace();
        }
    }

    private function createProfile() {
        return {
            :uuid => BloodSugar_SERVICE_UUID,

            :characteristics => [
                {
                    :uuid => BloodSugar_MEASUREMENT_UUID,

                    :descriptors => [BluetoothLowEnergy.cccdUuid()],
                },
            ],
        };
    }

    public function profileRegistrationFinished(
        status as BluetoothLowEnergy.Status
    ) as Void {
        _profileReady = status == BluetoothLowEnergy.STATUS_SUCCESS;

        if (!_profileReady) {
            _registrationRequested = false;
        }
    }

    public function isProfileReady() as Boolean {
        return _profileReady;
    }
}
