/*
MIT License

Copyright (c) 2026 Sebastiaan den Hertog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarDelegate extends WatchUi.BehaviorDelegate {
    private var _parentView as BloodSugarView;

    // 0 = value, 1 = context, 2 = confirm
    private var _stage as Number;
    private var _bloodSugarMmol as Float;
    private var _useMgdl as Boolean;
    private var _contextIndex as Number;
    private var _message as String;

    private var _editingTime;
    private var _isEditing as Boolean;
    private var _canDeleteReading as Boolean;

    public function initialize(view as BloodSugarView, bloodSugarValueTime) {
        BehaviorDelegate.initialize();

        _parentView = view;
        _stage = 0;
        _useMgdl = BloodSugarStore.getUseMgdl();
        _contextIndex = BloodSugarStore.getDefaultContextIndex();
        _message = "";
        _editingTime = bloodSugarValueTime;
        _isEditing = false;
        _canDeleteReading = false;

        loadStartingValue();
        updateView();
    }

    private function loadStartingValue() as Void {
        if (_editingTime != null) {
            var reading = BloodSugarStore.getReadingByTime(_editingTime);

            if (reading != null) {
                _isEditing = true;

                _canDeleteReading = isManualReading(reading);

                _bloodSugarMmol =
                    reading[BloodSugarReading.VALUE_MMOL].toFloat();
                if (
                    reading.size() > BloodSugarReading.CONTEXT &&
                    reading[BloodSugarReading.CONTEXT] != null
                ) {
                    _contextIndex = BloodSugarStore.getContextIndex(
                        reading[BloodSugarReading.CONTEXT].toString()
                    );
                }

                return;
            }

            _editingTime = null;
            _message = "Reading not found";
        }

        var latest = BloodSugarStore.getLatestReading();
        if (latest != null && latest.size() > BloodSugarReading.VALUE_MMOL) {
            _bloodSugarMmol = latest[BloodSugarReading.VALUE_MMOL].toFloat();
        } else {
            _bloodSugarMmol = 5.5f;
        }
    }

    public function onSelect() as Boolean {
        _message = "";

        if (_stage == 0) {
            _stage = 1;
        } else if (_stage == 1) {
            if (BloodSugarStore.getConfirmBeforeSave()) {
                _stage = 2;
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
        if (_stage == 0) {
            adjustDisplayedValue(getStepSize());
        } else if (_stage == 1) {
            _contextIndex = BloodSugarStore.normalizeContextIndex(
                _contextIndex - 1
            );
            updateView();
        }

        return true;
    }

    public function onNextPage() as Boolean {
        if (_stage == 0) {
            adjustDisplayedValue(-getStepSize());
        } else if (_stage == 1) {
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
        var saved = false;
        if (_isEditing) {
            saved = BloodSugarStore.updateReadingByTime(
                _editingTime,
                _bloodSugarMmol,
                context
            );
        } else {
            saved = BloodSugarStore.addReading(
                _bloodSugarMmol,
                BloodSugarReading.SOURCE_MANUAL,
                context
            );
        }

        if (!saved) {
            if (_isEditing) {
                _message = "Could not update reading";
            } else {
                _message = "Could not save reading";
            }
            _stage = 2;
            updateView();
            return;
        }
        var view = new BloodSugarHistoryListView();
        var delegate = new BloodSugarHistoryListDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_RIGHT);
    }

    public function onMenu() as Boolean {
        _message = "";
        if (!_isEditing || _editingTime == null) {
            _message = "Nothing to delete";
            updateView();
            return true;
        }

        if (!_canDeleteReading) {
            _message = "Imported reading";
            updateView();
            return true;
        }
        showDeleteConfirmation();
        return true;
    }

    private function updateView() as Void {
        _parentView.setEntry(
            getDisplayedValue(),
            _stage,
            _useMgdl,
            BloodSugarStore.getContextLabel(_contextIndex),
            _message,
            _isEditing,
            _canDeleteReading
        );
    }

    private function isManualReading(reading) as Boolean {
        if (!(reading instanceof Array)) {
            return false;
        }

        if (reading.size() <= BloodSugarReading.SOURCE) {
            return false;
        }

        if (reading[BloodSugarReading.SOURCE] == null) {
            return false;
        }

        return reading[BloodSugarReading.SOURCE]
            .toString()
            .equals(BloodSugarReading.SOURCE_MANUAL);
    }

    private function showDeleteConfirmation() as Void {
        var confirmation = new WatchUi.Confirmation("Delete reading?");
        var delegate = new BloodSugarDeleteReadingConfirmationDelegate(
            self,
            _editingTime
        );

        WatchUi.pushView(confirmation, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    public function handleDeleteReading(timestamp) as Void {
        if (!_isEditing || _editingTime == null || timestamp == null) {
            _message = "Reading changed";
            updateView();
            return;
        }

        if (timestamp.toNumber() != _editingTime.toNumber()) {
            _message = "Reading changed";
            updateView();
            return;
        }

        if (!_canDeleteReading) {
            _message = "Imported reading";
            updateView();
            return;
        }

        if (!BloodSugarStore.deleteReadingByTime(_editingTime)) {
            _message = "Could not delete reading";
            updateView();
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
