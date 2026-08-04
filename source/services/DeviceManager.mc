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
