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

import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;

/* Small persistence boundary shared by foreground, glance, and background. */
module BloodSugarSharedStorage {
    (:typecheck(false))
    function readValue(key as String) as Object? {
        return Storage.getValue(key);
    }

    (:typecheck(false))
    function writeValue(key as String, value as Object?) as Void {
        Storage.setValue(key, value);
    }

    (:typecheck(false))
    function deleteValue(key as String) as Void {
        Storage.deleteValue(key);
    }

    (:typecheck(false))
    function readProperty(key as String) as Object? {
        return Properties.getValue(key);
    }

    (:typecheck(false))
    function writeProperty(key as String, value as Object?) as Void {
        Properties.setValue(key, value);
    }

    function readString(key as String) as String? {
        var value = readValue(key);
        if (value instanceof String && (value as String).length() > 0) {
            return value as String;
        }
        return null;
    }
}
