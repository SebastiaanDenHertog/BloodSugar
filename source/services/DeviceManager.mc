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
import Toybox.Lang;
import Toybox.System;

class DeviceManager {
    private var _profileManager as ProfileManager?;
    private var _device as Device?;
    private var _onDeviceFound as WeakReference?;

    public function initialize(
        bleDelegate as BloodSugarServiceBleDelegate,
        profileManager as ProfileManager
    ) {
        _device = null;
        _profileManager = profileManager;

        bleDelegate.notifyScanResult(self);
        bleDelegate.notifyConnection(self);
        bleDelegate.notifyCharWrite(self);
    }

    public function notifyDeviceFound(
        delegate as BloodSugarSetupBleDelegate
    ) as Void {
        _onDeviceFound = delegate.weak();
    }

    public function start() as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    }

    public function stop() as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
    }

    public function procScanResult(scanResult as ScanResult) as Void {
        stop();

        if (_onDeviceFound != null && _onDeviceFound.stillAlive()) {
            (_onDeviceFound.get() as BloodSugarSetupBleDelegate).onDeviceFound(
                scanResult
            );
        }
    }

    public function connect(scanResult as ScanResult) as Void {
        BluetoothLowEnergy.pairDevice(scanResult);
    }

    public function procConnection(device as Device) as Void {
        if (device.isConnected()) {
            _device = device;
        } else {
            _device = null;
        }
    }

    public function procCharWrite(characteristic, status) as Void {
        System.println(
            "Proc Write: (" +
                characteristic.getUuid().toString() +
                ") - " +
                status.toString()
        );
    }
}
