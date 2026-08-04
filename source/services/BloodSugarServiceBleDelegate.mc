import Toybox.Lang;
import Toybox.BluetoothLowEnergy;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarServiceBleDelegate extends BluetoothLowEnergy.BleDelegate {
    private var _profileManager as ProfileManager;

    private var _onScanResult as WeakReference?;
    private var _onConnection as WeakReference?;
    private var _onCharWrite as WeakReference?;

    public function initialize(profileManager as ProfileManager) {
        BleDelegate.initialize();
        _profileManager = profileManager;
    }

    public function onProfileRegister(
        uuid as BluetoothLowEnergy.Uuid,
        status as BluetoothLowEnergy.Status
    ) as Void {
        if (!uuid.equals(_profileManager.BloodSugar_SERVICE_UUID)) {
            return;
        }

        _profileManager.profileRegistrationFinished(status);

        if (status == BluetoothLowEnergy.STATUS_SUCCESS) {
        } else {
        }
    }

    public function onScanResults(scanResults as Iterator) as Void {
        for (
            var result = scanResults.next();
            result != null;
            result = scanResults.next()
        ) {
            if (result instanceof ScanResult) {
                System.println("onBLEScan" + result);
                if (
                    contains(
                        result.getServiceUuids(),
                        _profileManager.BloodSugar_SERVICE_UUID
                    )
                ) {
                    broadcastScanResult(result);
                }
            }
        }
    }

    public function onConnectedStateChanged(
        device as BluetoothLowEnergy.Device,
        state as BluetoothLowEnergy.ConnectionState
    ) as Void {
        if (_onConnection != null && _onConnection.stillAlive()) {
            (_onConnection.get() as DeviceManager).procConnection(device);
        }
    }

    public function onCharacteristicWrite(characteristic, status) as Void {
        if (_onCharWrite != null) {
            if (_onCharWrite.stillAlive()) {
                (_onCharWrite.get() as DeviceManager).procCharWrite(
                    characteristic,
                    status
                );
            }
        }
    }

    public function notifyScanResult(manager as DeviceManager) as Void {
        _onScanResult = manager.weak();
    }

    public function notifyConnection(manager as DeviceManager) as Void {
        _onConnection = manager.weak();
    }

    public function notifyCharWrite(manager as DeviceManager) as Void {
        _onCharWrite = manager.weak();
    }

    private function broadcastScanResult(scanResult as ScanResult) as Void {
        if (_onScanResult != null) {
            if (_onScanResult.stillAlive()) {
                (_onScanResult.get() as DeviceManager).procScanResult(
                    scanResult
                );
            }
        }
    }

    public function onCharacteristicChanged(
        characteristic as BluetoothLowEnergy.Characteristic,
        value as Lang.ByteArray
    ) as Void {
        if (
            !characteristic
                .getUuid()
                .equals(_profileManager.BloodSugar_MEASUREMENT_UUID)
        ) {
            return;
        }

        if (value.size() < 4) {
            return;
        }

        var bloodSugarValue = parseBloodSugarBytes(value);

        BloodSugarStore.addReading(bloodSugarValue, "ble", "none");
        WatchUi.requestUpdate();
    }

    private function parseBloodSugarBytes(bytes as Lang.ByteArray) as Float {
        return (
            bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {
                :offset => 0,
                :endianness => Lang.ENDIAN_LITTLE,
            }) as Float
        );
    }

    private function contains(iter as Iterator, obj as Uuid) as Boolean {
        for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
            if (uuid.equals(obj)) {
                return true;
            }
        }

        return false;
    }
}
