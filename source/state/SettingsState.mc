import Toybox.Lang;

class SettingsState {
    public var mode as Number = 0;
    public var selected as Number = 0;
    public var zoneSelected as Number = 0;
    public var editing as Boolean = false;
    public var useMgdl as Boolean = false;

    public var zones as Array<Float> = [0.0, 0.0, 0.0, 0.0];

    public var notificationsEnabled as Boolean = false;
    public var notificationLowMmol as Float = 0.0;
    public var notificationHighMmol as Float = 0.0;

    public var contextIndex as Number = 0;
    public var confirmBeforeSave as Boolean = false;
    public var status as String = "";
}
