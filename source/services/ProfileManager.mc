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
