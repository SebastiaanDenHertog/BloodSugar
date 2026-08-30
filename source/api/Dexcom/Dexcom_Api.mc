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

import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;

import api;

(:background)
class DexcomApi {
    const US_SERVER = "https://share2.dexcom.com/ShareWebServices/Services/";
    const OUS_SERVER =
        "https://shareous1.dexcom.com/ShareWebServices/Services/";
    const JP_SERVER = "https://share.dexcom.jp/ShareWebServices/Services/";

    const DEFAULT_SERVER = OUS_SERVER;

    const STANDARD_APPLICATION_ID = "d89443d2-327c-4a6f-89e5-496bbb0317db";
    const JP_APPLICATION_ID = "d8665ade-9673-4e27-9ff6-92db4ce13d13";
    const DEFAULT_UUID = "00000000-0000-0000-0000-000000000000";

    const AUTHENTICATE_PATH = "General/AuthenticatePublisherAccount";
    const LOGIN_PATH = "General/LoginPublisherAccountById";
    const READINGS_PATH = "Publisher/ReadPublisherLatestGlucoseValues";

    const STATE_IDLE = 0;
    const STATE_AUTHENTICATE = 1;
    const STATE_LOGIN = 2;
    const STATE_READINGS = 3;

    const READING_MINUTES = 30;
    const READING_MAX_COUNT = 6;

    private var _username as String;
    private var _password as String;
    private var _baseUrl as String;
    private var _applicationId as String;
    private var _accountId as String?;
    private var _sessionId as String?;
    private var _state as Number;
    private var _authenticationRetried as Boolean;
    private var _cancelled as Boolean;
    private var _completion as BloodSugarApiReadCallback?;

    public function initialize(
        username as String,
        password as String,
        server as String
    ) {
        _username = username;
        _password = password;
        _baseUrl = isShareServer(server) ? server : DEFAULT_SERVER;
        _applicationId = _baseUrl.equals(JP_SERVER)
            ? JP_APPLICATION_ID
            : STANDARD_APPLICATION_ID;

        _accountId = BloodSugarApiStore.getAccountId(
            BloodSugarMonitor.DEXCOM,
            _username,
            _baseUrl
        );
        _sessionId = BloodSugarApiStore.getSessionId(
            BloodSugarMonitor.DEXCOM,
            _username,
            _baseUrl
        );

        if (_accountId == null && isUuid(_username)) {
            _accountId = _username;
        }

        _state = STATE_IDLE;
        _authenticationRetried = false;
        _cancelled = false;
        _completion = null;
    }

    public function read(completion as BloodSugarApiReadCallback) as Void {
        if (_state != STATE_IDLE) {
            return;
        }

        _completion = completion;
        _authenticationRetried = false;
        _cancelled = false;

        if (_sessionId != null) {
            loadReadings();
            return;
        }
        if (_accountId != null) {
            login();
            return;
        }
        authenticate();
    }

    private function authenticate() as Void {
        _state = STATE_AUTHENTICATE;
        var params =
            ({
                "accountName" => _username,
                "password" => _password,
                "applicationId" => _applicationId,
            }) as Dictionary<Object, Object>;

        Communications.makeWebRequest(
            _baseUrl + AUTHENTICATE_PATH,
            params,
            createPostOptions(),
            method(:onAuthenticateResponse)
        );
    }

    public function onAuthenticateResponse(
        responseCode as Number,
        response as
            Lang.Array or
                Lang.Dictionary or
                Lang.String or
                PersistedContent.Iterator or
                Null
    ) as Void {
        if (_cancelled) {
            return;
        }
        if (responseCode != 200) {
            fail(getRequestError("sign in", responseCode, response));
            return;
        }
        if (!(response instanceof Lang.String) || !isUuid(response as String)) {
            fail("Dexcom Share did not return a valid account ID");
            return;
        }

        _accountId = response as String;
        login();
    }

    private function login() as Void {
        if (_accountId == null) {
            fail("Dexcom Share account ID is missing");
            return;
        }

        _state = STATE_LOGIN;
        var params =
            ({
                "accountId" => _accountId as String,
                "password" => _password,
                "applicationId" => _applicationId,
            }) as Dictionary<Object, Object>;

        Communications.makeWebRequest(
            _baseUrl + LOGIN_PATH,
            params,
            createPostOptions(),
            method(:onLoginResponse)
        );
    }

    public function onLoginResponse(
        responseCode as Number,
        response as
            Lang.Array or
                Lang.Dictionary or
                Lang.String or
                PersistedContent.Iterator or
                Null
    ) as Void {
        if (_cancelled) {
            return;
        }
        if (responseCode != 200) {
            fail(getRequestError("create a session", responseCode, response));
            return;
        }
        if (!(response instanceof Lang.String) || !isUuid(response as String)) {
            fail("Dexcom Share did not return a valid session ID");
            return;
        }

        _sessionId = response as String;
        if (
            !BloodSugarApiStore.saveSession(
                BloodSugarMonitor.DEXCOM,
                _username,
                _baseUrl,
                _accountId as String,
                _sessionId as String
            )
        ) {
            fail("Dexcom connected, but its session could not be saved");
            return;
        }
        loadReadings();
    }

    private function loadReadings() as Void {
        if (_sessionId == null) {
            fail("Dexcom Share session is missing");
            return;
        }

        _state = STATE_READINGS;
        var url =
            _baseUrl +
            READINGS_PATH +
            "?sessionId=" +
            (_sessionId as String) +
            "&minutes=" +
            READING_MINUTES.toString() +
            "&maxCount=" +
            READING_MAX_COUNT.toString();

        Communications.makeWebRequest(
            url,
            ({}) as Dictionary<Object, Object>,
            createPostOptions(),
            method(:onReadingsResponse)
        );
    }

    public function onReadingsResponse(
        responseCode as Number,
        response as
            Lang.Array or
                Lang.Dictionary or
                Lang.String or
                PersistedContent.Iterator or
                Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode != 200) {
            if (!_authenticationRetried && isSessionError(response)) {
                _authenticationRetried = true;
                _sessionId = null;
                BloodSugarApiStore.clearSession(BloodSugarMonitor.DEXCOM);
                if (_accountId != null) {
                    login();
                } else {
                    authenticate();
                }
                return;
            }

            fail(getRequestError("load readings", responseCode, response));
            return;
        }

        if (!(response instanceof Lang.Array)) {
            fail("Dexcom Share readings response was not a JSON array");
            return;
        }

        var records = response as ApiArray;
        if (records.size() == 0) {
            complete(0, 0.0, 0);
            return;
        }

        var readings = [] as Array<BloodSugarPackedReading.IncomingRecord>;
        var latestTimestamp = 0;
        var latestValueMmol = 0.0f;

        for (var index = 0; index < records.size(); index += 1) {
            if (!(records[index] instanceof Lang.Dictionary)) {
                continue;
            }

            var record = records[index] as ApiDictionary;
            var valueMgdl = api.getNumber(record, "Value", 0);
            var timestampText = api.getString(record, "DT", "");
            if (timestampText.length() == 0) {
                timestampText = api.getString(record, "WT", "");
            }
            var timestamp = parseShareTimestamp(timestampText);

            if (timestamp == null || valueMgdl <= 0) {
                continue;
            }

            var valueMmol = BloodSugarSharedSettings.mgdlToMmol(
                valueMgdl.toFloat()
            );
            readings.add([
                timestamp as Number,
                valueMmol,
                BloodSugarPackedReading.SOURCE_DEXCOM,
                BloodSugarPackedReading.DEFAULT_CONTEXT,
            ]);

            if ((timestamp as Number) > latestTimestamp) {
                latestTimestamp = timestamp as Number;
                latestValueMmol = valueMmol;
            }
        }

        if (readings.size() == 0) {
            complete(0, 0.0, 0);
            return;
        }

        var addedCount = BloodSugarBackgroundHistoryStore.addReadings(
            readings
        );
        if (addedCount < 0) {
            fail("Dexcom Share readings could not be stored");
            return;
        }
        complete(latestTimestamp, latestValueMmol, addedCount);
    }

    private function createPostOptions() as Dictionary {
        return {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => ({
                "Accept" => "application/json",
                "Accept-Encoding" => "application/json",
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            }) as Dictionary<String, String>,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
    }

    private function parseShareTimestamp(value as String) as Number? {
        var open = value.find("Date(");
        var close = value.find(")");
        if (open == null || close == null || close <= open + 5) {
            return null;
        }

        var raw = value.substring((open as Number) + 5, close as Number);
        var offset = raw.find("+");
        var minus = raw.find("-");
        if (offset == null || (minus != null && minus < offset)) {
            offset = minus;
        }
        if (offset != null) {
            raw = raw.substring(0, offset as Number);
        }
        if (raw.length() < 10) {
            return null;
        }

        /* Share timestamps are milliseconds; epoch seconds fit in Number. */
        if (raw.length() > 10) {
            raw = raw.substring(0, raw.length() - 3);
        }
        return raw.toNumber();
    }

    private function isUuid(value as String) as Boolean {
        return (
            value.length() == 36 &&
            value.substring(8, 9).equals("-") &&
            value.substring(13, 14).equals("-") &&
            value.substring(18, 19).equals("-") &&
            value.substring(23, 24).equals("-") &&
            !value.equals(DEFAULT_UUID)
        );
    }

    private function isShareServer(server as String) as Boolean {
        return (
            server.equals(US_SERVER) ||
            server.equals(OUS_SERVER) ||
            server.equals(JP_SERVER)
        );
    }

    private function isSessionError(response as Object?) as Boolean {
        if (!(response instanceof Lang.Dictionary)) {
            return false;
        }
        var code = api.getString(response as ApiDictionary, "Code", "");
        return (
            code.equals("SessionIdNotFound") || code.equals("SessionNotValid")
        );
    }

    private function getRequestError(
        action as String,
        responseCode as Number,
        response as Object?
    ) as String {
        if (response instanceof Lang.Dictionary) {
            var error = response as ApiDictionary;
            var code = api.getString(error, "Code", "");
            var message = api.getString(error, "Message", "");
            if (
                code.equals("AccountPasswordInvalid") ||
                (code.equals("SSO_InternalError") &&
                    message.find("Cannot Authenticate") != null) ||
                (code.equals("InvalidArgument") &&
                    (message.find("accountName") != null ||
                        message.find("password") != null))
            ) {
                return "Incorrect Dexcom username or password";
            }
            if (code.equals("SSO_AuthenticateMaxAttemptsExceeded")) {
                return "Too many Dexcom sign-in attempts. Try again later.";
            }

            if (code.length() > 0) {
                return "Dexcom Share " + code;
            }
            if (message.length() > 0) {
                return message;
            }
        }

        if (responseCode == Communications.NETWORK_RESPONSE_TOO_LARGE) {
            return "Dexcom Share response was too large for the watch";
        }
        if (responseCode < 0) {
            return "Dexcom Garmin network error " + responseCode.toString();
        }
        return (
            "Could not " +
            action +
            " from Dexcom Share: HTTP " +
            responseCode.toString()
        );
    }

    public function cancel() as Void {
        _cancelled = true;
        _state = STATE_IDLE;
        _completion = null;
        Communications.cancelAllRequests();
    }

    private function complete(
        latestTimestamp as Number,
        latestValueMmol as Float,
        addedCount as Number
    ) as Void {
        var completion = _completion;
        _state = STATE_IDLE;
        _completion = null;

        if (completion != null) {
            completion.invoke(
                true,
                latestTimestamp,
                latestValueMmol,
                addedCount,
                ""
            );
        }
    }

    private function fail(message as String) as Void {
        var completion = _completion;
        _state = STATE_IDLE;
        _completion = null;
        System.println("DexcomApi: " + message);

        if (completion != null) {
            completion.invoke(false, 0, 0.0, 0, message);
        }
    }
}
