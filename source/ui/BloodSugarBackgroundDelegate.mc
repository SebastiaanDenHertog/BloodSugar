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

import Toybox.Background;
import Toybox.System;
import Toybox.Lang;

(:background)
class BloodSugarBackgroundDelegate extends System.ServiceDelegate {
    private var _client as AbbottFreeStyleApi?;

    public function initialize() {
        ServiceDelegate.initialize();

        _client = null;
    }

    public function onTemporalEvent() as Void {
        var username = BloodSugarStore.getUsername();

        var password = BloodSugarStore.getPassword();

        if (username.length() == 0 || password.length() == 0) {
            Background.exit(null);
            return;
        }

        var client = new AbbottFreeStyleApi(username, password);

        _client = client;

        client.read(method(:onReadComplete));
    }

    private function onReadComplete(
        success as Boolean,
        currentReading,
        addedCount as Number,
        errorMessage as String
    ) as Void {
        _client = null;

        var result = {
            "success" => success,
            "addedCount" => addedCount,
            "errorMessage" => errorMessage,
        };

        Background.exit(result);
    }

    public function registerBloodSugarBackgroundPolling() as Void {
        Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    }
}
