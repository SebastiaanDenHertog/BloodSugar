import Toybox.BluetoothLowEnergy;
import Toybox.System;
import Toybox.Lang;

class ProfileManager {

    public const BloodSugar_SERVICE_UUID =
        BluetoothLowEnergy.longToUuid(
            0xEF6805009B354933L,
            0x9B1052FFA9740042L
        );

    public const BloodSugar_MEASUREMENT_UUID =
        BluetoothLowEnergy.longToUuid(
            0xEF6805019B354933L,
            0x9B1052FFA9740042L
        );

    // Voorkomt meerdere registerProfile()-aanroepen,
    // ook wanneer per ongeluk meerdere ProfileManagers worden gemaakt.
    private static var _registrationRequested as Boolean = false;

    private var _profileReady as Boolean = false;

    public function initialize() {
    }

    public function registerProfiles() as Void {
        if (_registrationRequested) {
            System.println("BLE-profiel is al aangevraagd");
            return;
        }

        _registrationRequested = true;

        try {
            BluetoothLowEnergy.registerProfile(createProfile());
        } catch (
            exception
            instanceof BluetoothLowEnergy.ProfileRegistrationException
        ) {
            _registrationRequested = false;

            System.println("BLE-profiel kon niet worden geregistreerd");
            exception.printStackTrace();
        }
    }

    private function createProfile() {
        return {
            :uuid => BloodSugar_SERVICE_UUID,

            :characteristics => [{
                :uuid => BloodSugar_MEASUREMENT_UUID,

                // De echte standaard CCCD voor notifications.
                :descriptors => [
                    BluetoothLowEnergy.cccdUuid()
                ]
            }]
        };
    }

    public function profileRegistrationFinished(
        status as BluetoothLowEnergy.Status
    ) as Void {
        _profileReady =
            status == BluetoothLowEnergy.STATUS_SUCCESS;

        if (!_profileReady) {
            // Hiermee kan eventueel later opnieuw worden geprobeerd.
            _registrationRequested = false;
        }
    }

    public function isProfileReady() as Boolean {
        return _profileReady;
    }
}