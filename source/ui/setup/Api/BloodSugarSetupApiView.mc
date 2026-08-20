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

import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class BloodSugarSetupApiView extends WatchUi.Menu2 {
    private var _usernameItem as WatchUi.MenuItem;
    private var _passwordItem as WatchUi.MenuItem;
    private var _connectItem as WatchUi.MenuItem;

    public function initialize() {
        Menu2.initialize({ :title => "Account credentials" });

        _usernameItem = new WatchUi.MenuItem(
            "Username",
            "Enter username",
            :username,
            {}
        );
        _passwordItem = new WatchUi.MenuItem(
            "Password",
            "Enter password",
            :password,
            {}
        );
        _connectItem = new WatchUi.MenuItem(
            "Connect",
            "Test and save account",
            :connect,
            {}
        );

        addItem(_usernameItem);
        addItem(_passwordItem);
        addItem(_connectItem);
    }

    public function setState(
        username as String,
        passwordLength as Number,
        status as String,
        busy as Boolean
    ) as Void {
        _usernameItem.setSubLabel(getUsernameDisplay(username));
        _passwordItem.setSubLabel(getPasswordDisplay(passwordLength));
        _connectItem.setLabel(busy ? "Connecting..." : "Connect");
        _connectItem.setSubLabel(
            status.length() > 0 ? status : "Test and save account"
        );

        updateItem(_usernameItem, 0);
        updateItem(_passwordItem, 1);
        updateItem(_connectItem, 2);
    }

    public function focusItem(index as Number) as Void {
        setFocus(index);
    }

    private function getUsernameDisplay(username as String) as String {
        if (username.length() == 0) {
            return "Enter username";
        }
        return shorten(username, 24);
    }

    private function getPasswordDisplay(passwordLength as Number) as String {
        if (passwordLength == 0) {
            return "Enter password";
        }

        var visibleLength = passwordLength;
        var masked = "";
        if (visibleLength > 16) {
            visibleLength = 16;
        }

        for (var index = 0; index < visibleLength; index++) {
            masked += "*";
        }
        if (passwordLength > visibleLength) {
            masked += "+";
        }
        return masked;
    }

    private function shorten(
        value as String,
        maximumLength as Number
    ) as String {
        if (value.length() <= maximumLength) {
            return value;
        }
        return value.substring(0, maximumLength - 3) + "...";
    }
}
