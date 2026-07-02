import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BloodSugarView extends WatchUi.View {

    private var _bloodSugar;
    private var _actionHits as Number;
    private var _behaviorHits as Number;
    private var _behavior as Behavior;
    private var _action as Action;

    public function initialize() {
        View.initialize();
        _bloodSugar = 0.0;
        _actionHits = 0;
        _behaviorHits = 0;
        _behavior = $.BEHAVIOR_NONE;
        _action = $.ACTION_NONE;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
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

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();


        var dy = dc.getFontHeight(Graphics.FONT_SMALL);
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        y -= (4 * dy) / 2;

        dc.drawText(x, y, Graphics.FONT_SMALL, _bloodSugar.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }   

    function onHide() as Void {
    }

    public function setBloodSugar(bloodSugar) as Void {
        _bloodSugar = bloodSugar;
        WatchUi.requestUpdate();
    }
}
