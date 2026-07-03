import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class BloodSugarDelegate extends WatchUi.BehaviorDelegate {

    private var _parentView as BloodSugarView;

    // 0 = waiting
    // 1 = edit whole number
    // 2 = edit decimal
    // 3 = select unit
    // 4 = confirm
    private var _stage as Number;

    // Always store the internal value in mmol/L.
    private var _bloodSugarMmol as Float;

    // false = mmol/L
    // true  = mg/dL
    private var _useMgdl as Boolean;

    public function initialize(view as BloodSugarView) {
        BehaviorDelegate.initialize();

        _parentView = view;
        _stage = 0;
        _bloodSugarMmol = 0.0f;
        _useMgdl = false;

        updateView();

        System.println("BloodSugarDelegate initialized");
    }

    public function onSelect() as Boolean {
        if (_stage < 4) {
            _stage += 1;

            System.println("New stage: " + _stage);

            updateView();
            return true;
        }

        saveReading();
        return true;
    }

    // UP
    public function onPreviousPage() as Boolean {
        if (_stage == 1) {
            // Increase by 1.0 in the currently selected unit.
            adjustDisplayedValue(1.0f);
            return true;
        } else if (_stage == 2) {
            // Increase by 0.1 in the currently selected unit.
            adjustDisplayedValue(0.1f);
            return true;
        } else if (_stage == 3) {
            // Select mmol/L.
            selectUnit(false);
            return true;
        }

        var view = new $.BloodSugarHistoryView();
        var delegate = new $.BloodSugarHistoryDelegate(view);

        WatchUi.pushView(
            view,
            delegate,
            WatchUi.SLIDE_RIGHT
        );

        return true;
    }

    // DOWN
    public function onNextPage() as Boolean {
        if (_stage == 1) {
            // Decrease by 1.0 in the currently selected unit.
            adjustDisplayedValue(-1.0f);
        } else if (_stage == 2) {
            // Decrease by 0.1 in the currently selected unit.
            adjustDisplayedValue(-0.1f);
        } else if (_stage == 3) {
            // Select mg/dL.
            selectUnit(true);
        }

        return true;
    }

    public function onBack() as Boolean {
        if (_stage > 0) {
            _stage -= 1;
            updateView();

            return true;
        }

        System.exit();

        //return true;
    }

    private function selectUnit(useMgdl as Boolean) as Void {
        _useMgdl = useMgdl;

        System.println(
            "Selected unit: " + getUnitText()
        );

        // updateView() recalculates the displayed value.
        updateView();
    }

    private function adjustDisplayedValue(
        delta as Float
    ) as Void {
        // Convert the adjustment to mmol/L before modifying
        // the internally stored value.
        if (_useMgdl) {
            _bloodSugarMmol +=
                BloodSugarStore.MgdlToMoll(delta);
        } else {
            _bloodSugarMmol += delta;
        }

        if (_bloodSugarMmol < 0.0f) {
            _bloodSugarMmol = 0.0f;
        }

        updateView();
    }

    private function getDisplayedValue() as Float {
        if (_useMgdl) {
            return BloodSugarStore.MollToMgdl(
                _bloodSugarMmol
            );
        }

        return _bloodSugarMmol;
    }

    private function saveReading() as Void {
        var displayedValue = getDisplayedValue();

        System.println(
            "Entered value: "
            + displayedValue
            + " "
            + getUnitText()
        );

        System.println(
            "Stored mmol/L value: "
            + _bloodSugarMmol
        );

        // The store receives a consistent mmol/L value.
        BloodSugarStore.addReading(_bloodSugarMmol);

        var view = new $.BloodSugarHistoryView();
        var delegate = new $.BloodSugarHistoryDelegate(view);

        WatchUi.pushView(
            view,
            delegate,
            WatchUi.SLIDE_RIGHT
        );
    }

    private function updateView() as Void {
        _parentView.setBloodSugar(
            getDisplayedValue(),
            _stage,
            _useMgdl
        );
    }

    private function getUnitText() as String {
        if (_useMgdl) {
            return "mg/dL";
        }

        return "mmol/L";
    }
}