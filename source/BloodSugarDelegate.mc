import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarView;

    // 0 = ready, 1 = value, 2 = context, 3 = confirm
    private var _stage as Number;
    private var _bloodSugarMmol as Float;
    private var _useMgdl as Boolean;
    private var _contextIndex as Number;
    private var _message as String;

    public function initialize(view as BloodSugarView) {
        BehaviorDelegate.initialize();

        _parentView = view;
        _stage = 0;
        _useMgdl = BloodSugarStore.getUseMgdl();
        _contextIndex = BloodSugarStore.getDefaultContextIndex();
        _message = "";

        var latest = BloodSugarStore.getLatestReading();

        if (
            latest != null &&
            latest.size() > BloodSugarStore.READING_VALUE_MMOL
        ) {
            _bloodSugarMmol =
                latest[BloodSugarStore.READING_VALUE_MMOL].toFloat();
        } else {
            _bloodSugarMmol = 5.5f;
        }

        updateView();
    }

    public function onSelect() as Boolean {
        _message = "";

        if (_stage == 0) {
            _stage = 1;
        } else if (_stage == 1) {
            _stage = 2;
        } else if (_stage == 2) {
            if (BloodSugarStore.getConfirmBeforeSave()) {
                _stage = 3;
            } else {
                saveReading();
                return true;
            }
        } else {
            saveReading();
            return true;
        }

        updateView();
        return true;
    }

    public function onPreviousPage() as Boolean {
        if (_stage == 1) {
            adjustDisplayedValue(getStepSize());
        } else if (_stage == 2) {
            _contextIndex = BloodSugarStore.normalizeContextIndex(
                _contextIndex - 1
            );
            updateView();
        } else if (_stage == 0) {
            var view = new BloodSugarHistoryView();
            var delegate = new BloodSugarHistoryDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
        }

        return true;
    }

    public function onNextPage() as Boolean {
        if (_stage == 1) {
            adjustDisplayedValue(-getStepSize());
        } else if (_stage == 2) {
            _contextIndex = BloodSugarStore.normalizeContextIndex(
                _contextIndex + 1
            );
            updateView();
        }

        return true;
    }

    public function onBack() as Boolean {
        if (_stage > 0) {
            _stage -= 1;
            _message = "";
            updateView();
            return true;
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function getStepSize() as Float {
        if (_useMgdl) {
            return 1.0f;
        }

        return 0.1f;
    }

    private function adjustDisplayedValue(delta as Float) as Void {
        if (_useMgdl) {
            _bloodSugarMmol += BloodSugarStore.MgdlToMoll(delta);
        } else {
            _bloodSugarMmol += delta;
        }

        if (_bloodSugarMmol < 0.1f) {
            _bloodSugarMmol = 0.1f;
        }

        updateView();
    }

    private function getDisplayedValue() as Float {
        if (_useMgdl) {
            return BloodSugarStore.MollToMgdl(_bloodSugarMmol);
        }

        return _bloodSugarMmol;
    }

    private function saveReading() as Void {
        var context = BloodSugarStore.getContextKey(_contextIndex);
        var saved = BloodSugarStore.addReading(
            _bloodSugarMmol,
            "manual",
            context
        );

        if (!saved) {
            _message = "Could not save reading";
            _stage = 3;
            updateView();
            return;
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function updateView() as Void {
        _parentView.setEntry(
            getDisplayedValue(),
            _stage,
            _useMgdl,
            BloodSugarStore.getContextLabel(_contextIndex),
            _message
        );
    }
}
