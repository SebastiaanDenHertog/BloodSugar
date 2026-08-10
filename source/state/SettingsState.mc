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

import Toybox.Lang;

class SettingsState {
    public var mode as Number = 0;
    public var selected as Number = 0;
    public var zoneSelected as Number = 0;
    public var editing as Boolean = false;
    public var useMgdl as Boolean = false;

    public var zones as Array<Float> = [0.0f, 0.0f, 0.0f, 0.0f];

    public var notificationsEnabled as Boolean = false;
    public var notificationLowMmol as Float = 0.0f;
    public var notificationHighMmol as Float = 0.0f;

    public var contextIndex as Number = 0;
    public var confirmBeforeSave as Boolean = false;
    public var status as String = "";

    public var savedMode as Number = -1;
    public var savedIndex as Number = -1;
}
