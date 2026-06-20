import Toybox.Lang;
import Toybox.BluetoothLowEnergy;

class BloodSugarServiceDelegate extends BluetoothLowEnergy.BleDelegate {
    private var _profileManager as ProfileManager;

    private var _onScanResult as WeakReference?;
    private var _onConnection as WeakReference?;
    private var _onCharWrite as WeakReference?;

    public function initialize(profileManager as ProfileManager) {
        BleDelegate.initialize();
        _profileManager = profileManager;
    }

    public function onScanResults(scanResults as Iterator) as Void {
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            if (result instanceof ScanResult) {
                if (contains(result.getServiceUuids(), _profileManager.CLIENT_CHARACTERISTIC_CONFIGURATION_UUID)) {
                    broadcastScanResult(result);
                }
            }
        }
    }

    public function onConnectedStateChanged(device as Device, state as ConnectionState) as Void {
        if (_onConnection != null) {
            if (_onConnection.stillAlive()) {
                (_onConnection.get() as DeviceManager).procConnection(device);
            }
        }
    }

    public function onCharacteristicWrite(characteristic as Characteristic, status as Status) as Void {
        if (_onCharWrite != null) {
            if (_onCharWrite.stillAlive()) {
                (_onCharWrite.get() as DeviceManager).procCharWrite(characteristic, status);
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
                (_onScanResult.get() as DeviceManager).procScanResult(scanResult);
            }
        }
    }

    function onCharacteristicChanged(characteristic, value) {
        var BloodSugarValue = parseBloodSugarBytes(value);
        BloodSugarStore.addReading(BloodSugarValue);
        WatchUi.requestUpdate();
    }

    private function contains(iter as Iterator, obj as Uuid) as Boolean {
        for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
            if (uuid.equals(obj)) {
                return true;
            }
        }

        return false;
    }

    private function parseBloodSugarBytes(bytes) {
        var f = bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {
            :offset => 0,
            :endianness => Lang.ENDIAN_BIG // Use ENDIAN_LITTLE if reversed
        });

        return f;
    }
}