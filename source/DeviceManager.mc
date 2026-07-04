import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;

class DeviceManager {
    private var _profileManager as ProfileManager;
    private var _device as Device?;
    private var _BloodSugarService as Service?;
    private var _config as Characteristic?;
    private var _BloodSugarData as Characteristic?;
    private var _configComplete as Boolean = false;
    private var _sampleInProgress as Boolean = false;

    public function initialize(
        bleDelegate as BloodSugarServiceDelegate,
        profileManager as ProfileManager
    ) {
        _device = null;

        bleDelegate.notifyScanResult(self);
        bleDelegate.notifyConnection(self);
        bleDelegate.notifyCharWrite(self);
        _profileManager = profileManager;
    }

    public function start() as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    }

    public function procScanResult(scanResult as ScanResult) as Void {
        // Pair the first Thingy we see with good RSSI
        if (scanResult.getRssi() > -50) {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
            BluetoothLowEnergy.pairDevice(scanResult);
        }
    }

    public function procConnection(device as Device) as Void {
        if (device.isConnected()) {
            _device = device;
        } else {
            _device = null;
        }
    }

    public function procCharWrite(char, status) as Void {
        System.println("Proc Write: (" + char.getUuid() + ") - " + status);
    }
}
