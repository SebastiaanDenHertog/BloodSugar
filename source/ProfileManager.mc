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

    // Voorkomt meerdere registerProfile()-aanroepen,
    // ook wanneer per ongeluk meerdere ProfileManagers worden gemaakt.
    private static var _registrationRequested as Boolean = false;

    private var _profileReady as Boolean = false;

    public function initialize() {}

    public function registerProfiles() as Void {
        if (_registrationRequested) {
            System.println("BLE-profiel is al aangevraagd");
            return;
        }

        _registrationRequested = true;

        try {
            BluetoothLowEnergy.registerProfile(createProfile());
        } catch (exception instanceof
            BluetoothLowEnergy.ProfileRegistrationException) {
            _registrationRequested = false;

            System.println("BLE-profiel kon niet worden geregistreerd");
            exception.printStackTrace();
        }
    }

    private function createProfile() {
        return {
            :uuid => BloodSugar_SERVICE_UUID,

            :characteristics => [
                {
                    :uuid => BloodSugar_MEASUREMENT_UUID,

                    // De echte standaard CCCD voor notifications.
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
            // Hiermee kan eventueel later opnieuw worden geprobeerd.
            _registrationRequested = false;
        }
    }

    public function isProfileReady() as Boolean {
        return _profileReady;
    }
}
