import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarDelegate extends WatchUi.BehaviorDelegate {

    private var _parentView as BloodSugarView;
    private var _buttonsPressed as Number?;
    private var _buttonsExpected as ButtonInputs?;
    private var _lastKey as Key?;
    private var _lastBehavior as String?;
    private var _bloodSugar as Float?;

    private var userInput;

    public function initialize(view as BloodSugarView) {
        BehaviorDelegate.initialize();

        _buttonsPressed = 0;
        _parentView = view;
        _bloodSugar = 0.0;

        var deviceSettings = System.getDeviceSettings();
        _buttonsExpected = deviceSettings.inputButtons;
        userInput = [false,false,false]; // number, decial if there , confirm
        System.println("BloodSugerDelegate initialized:");
    }

    public function onSelect() as Boolean {
        System.println(userInput);
        System.println($.BEHAVIOR_SELECT);
        System.println(_lastBehavior);
        System.println($.BEHAVIOR_SELECT == _lastBehavior);
        if($.BEHAVIOR_SELECT.equals(_lastBehavior) && userInput[0] == false && userInput[1] == false && userInput[2] == false){
            userInput = [true,false,false];
            _lastBehavior = $.BEHAVIOR_SELECT;
            System.println("onSelect1" +userInput );
        }
        if($.BEHAVIOR_SELECT.equals(_lastBehavior) && userInput == [true,false,false]){
            userInput = [true,true,false];
            _lastBehavior = $.BEHAVIOR_SELECT;
            System.println("onSelect2" +userInput );
        }
        if($.BEHAVIOR_SELECT.equals(_lastBehavior) && userInput == [true,true,false]){
            userInput = [true,true,true];
            _lastBehavior = $.BEHAVIOR_SELECT;
            System.println("onSelect3" +userInput );
        }
        if($.BEHAVIOR_SELECT.equals(_lastBehavior) && userInput == [true,true,true]){
            _lastBehavior = $.BEHAVIOR_SELECT;
            System.println("onSelect4" +userInput );
            WatchUi.pushView(new $.BloodSugarHistoryView(), new $.BloodSugarHistoryDelegate(), WatchUi.SLIDE_RIGHT);
        }

        _lastBehavior = $.BEHAVIOR_SELECT;
       
        return true;
    }

    public function onBack() as Boolean {
        if($.BEHAVIOR_BACK.equals(_lastBehavior) && userInput == [false,false,false]){
            System.exit();
        }
        if($.BEHAVIOR_BACK.equals(_lastBehavior) && userInput == [true,false,false]){
            userInput = [false,false,false];
            _lastBehavior = $.BEHAVIOR_BACK;
        }
        if($.BEHAVIOR_BACK.equals(_lastBehavior) && userInput == [true,true,false]){
            userInput = [true,false,false];
            _lastBehavior = $.BEHAVIOR_BACK;
        }
        if($.BEHAVIOR_BACK.equals(_lastBehavior) && userInput == [true,true,true]){
            userInput = [true,true,false];
            _lastBehavior = $.BEHAVIOR_BACK;
        }

        _lastBehavior = $.BEHAVIOR_BACK;
        return true;
    }

    public function onPreviousPage() as Boolean {
        if(userInput == [false,false,false]){
            _lastBehavior = $.BEHAVIOR_PREV_PAGE;
        }
        if(userInput == [true,false,false]){
            _lastBehavior = $.BEHAVIOR_BACK;
            _bloodSugar = _bloodSugar + 1.0;
            _parentView.setBloodSugar(_bloodSugar);
            System.println("bloodsuger: " + _bloodSugar);
        }
        if(userInput == [true,true,false]){
            _lastBehavior = $.BEHAVIOR_BACK;
            _bloodSugar = _bloodSugar + 0.1;
            _parentView.setBloodSugar(_bloodSugar);
            System.println("bloodsuger: " + _bloodSugar);
        }
        if($.BEHAVIOR_BACK.equals(_lastBehavior) && userInput == [true,true,true]){
            _lastBehavior = $.BEHAVIOR_BACK;
        }
        
        _lastBehavior = $.BEHAVIOR_BACK;
        return true;
    }

}