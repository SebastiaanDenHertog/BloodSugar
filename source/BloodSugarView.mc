import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import BloodSugarStore;

class BloodSugarView extends WatchUi.View {

    private var _action as Action;
    private var _statusString as String;
    private var _behavior as Behavior;
    private var _button as Button;
    private var _actionHits as Number;
    private var _behaviorHits as Number;
    private var _BloodSugar as Float;

    public function initialize() {
        View.initialize();
        _action = $.ACTION_NONE;
        _behavior = $.BEHAVIOR_NONE;
        _statusString = $.STATUS_NONE;
        _button = $.BUTTON_PUSH;
        _actionHits = 0;
        _behaviorHits = 0;
        _BloodSugar = 0.0;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        _BloodSugar = BloodSugarStore.getHistory();

        var dy = dc.getFontHeight(Graphics.FONT_SMALL);
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        y -= (4 * dy) / 2;

        dc.drawText(x, y, Graphics.FONT_SMALL, _BloodSugar.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    public function setBehavior(newBehavior as Behavior) as Void {
        _behavior = newBehavior;
        _behaviorHits++;
        WatchUi.requestUpdate();
    }

    public function setStatusString(newStatus as String) as Void {
        _statusString = newStatus;
        WatchUi.requestUpdate();
    }

    public function setAction(newAction as Action) as Void {
        _action = newAction;
        _actionHits++;

        if (_actionHits > _behaviorHits) {
            _behavior = $.BEHAVIOR_NONE;
            _behaviorHits = _actionHits;
        }

        WatchUi.requestUpdate();
    }

    public function setButton(newButton as Button) as Void {
        _button = newButton;
        WatchUi.requestUpdate();
    }


    function onHide() as Void {
    }

}
