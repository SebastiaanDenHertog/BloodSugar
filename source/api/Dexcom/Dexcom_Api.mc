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
import Toybox.Cryptography;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.StringUtil;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

import BloodSugarStore;
import api;

(:background)
class DexcomApi {
    const SANDBOX_SERVER = "https://sandbox-api.dexcom.com";
    const US_SERVER = "https://api.dexcom.com";
    const EU_SERVER = "https://api.dexcom.eu";
    const JP_SERVER = "https://api.dexcom.jp";

    /*
     * New Zealand and other non-US accounts use Dexcom's EU API. Change this
     * to SANDBOX_SERVER while developing against Dexcom's simulated users.
     */
    const DEFAULT_SERVER = SANDBOX_SERVER;

    const AUTHORIZE_PATH = "/v3/oauth2/login";
    const TOKEN_PATH = "/v3/oauth2/token";
    const DATA_RANGE_PATH = "/v3/users/self/dataRange";
    const EGVS_PATH = "/v3/users/self/egvs";

    const REDIRECT_URI = "http://localhost";
    const OAUTH_CODE_KEY = "dexcomCode";
    const OAUTH_ERROR_KEY = "dexcomError";
    const OAUTH_STATE_KEY = "dexcomState";

    const STATE_IDLE = 0;
    const STATE_AUTHORIZE = 1;
    const STATE_TOKEN = 2;
    const STATE_REFRESH = 3;
    const STATE_DATA_RANGE = 4;
    const STATE_EGVS = 5;

    const TOKEN_EXPIRY_MARGIN_SECONDS = 60;
    /* Three to four EGV records stay comfortably below Garmin's payload cap. */
    const EGV_WINDOW_SECONDS = 15 * 60 * 24 * 30;

    private var _clientId as String;
    private var _clientSecret as String;
    private var _baseUrl as String;

    private var _bearerToken as String?;
    private var _refreshToken as String?;
    private var _accessTokenExpiresAt as Number;
    private var _oauthState as String?;

    private var _state as Number;
    private var _authenticationRetried as Boolean;
    private var _cancelled as Boolean;
    private var _completion as BloodSugarApiReadCallback?;

    public function initialize(id as String, secret as String) {
        _clientId = id;
        _clientSecret = secret;
        _baseUrl = BloodSugarStore.getApiServer(
            BloodSugarMonitor.DEXCOM,
            _clientId,
            DEFAULT_SERVER
        );

        _bearerToken = BloodSugarStore.getApiAccessToken(
            BloodSugarMonitor.DEXCOM,
            _clientId,
            _baseUrl
        );
        _refreshToken = BloodSugarStore.getApiRefreshToken(
            BloodSugarMonitor.DEXCOM,
            _clientId,
            _baseUrl
        );
        _accessTokenExpiresAt = BloodSugarStore.getApiTokenExpiresAt(
            BloodSugarMonitor.DEXCOM,
            _clientId,
            _baseUrl
        );
        _oauthState = null;

        _state = STATE_IDLE;
        _completion = null;
        _authenticationRetried = false;
        _cancelled = false;
    }

    public function read(completion as BloodSugarApiReadCallback) as Void {
        if (_state != STATE_IDLE) {
            return;
        }

        _completion = completion;
        _authenticationRetried = false;
        _cancelled = false;

        if (
            _bearerToken != null &&
            (_accessTokenExpiresAt == 0 ||
                _accessTokenExpiresAt >
                    Time.now().value() + TOKEN_EXPIRY_MARGIN_SECONDS)
        ) {
            loadDataRange();
            return;
        }

        if (_refreshToken != null) {
            refreshAccessToken();
            return;
        }

        authorize();
    }

    private function authorize() as Void {
        _state = STATE_AUTHORIZE;
        var savedState = BloodSugarStore.getApiAuthorizationState(
            BloodSugarMonitor.DEXCOM,
            _clientId
        );
        if (savedState.length() > 0) {
            _oauthState = savedState;
        } else {
            _oauthState = createOAuthState();

            if (
                !BloodSugarStore.saveApiAuthorizationState(
                    BloodSugarMonitor.DEXCOM,
                    _clientId,
                    _oauthState as String
                )
            ) {
                fail("Could not save Dexcom sign-in state");
                return;
            }
        }

        Communications.registerForOAuthMessages(method(:onOAuthMessage));

        /* Registration can synchronously deliver a response cached by Garmin. */
        if (_state != STATE_AUTHORIZE || _cancelled) {
            return;
        }

        var params =
            ({
                "client_id" => _clientId,
                "redirect_uri" => REDIRECT_URI,
                "response_type" => "code",
                "scope" => "offline_access",
                "state" => _oauthState as String,
            }) as Dictionary<String, String>;

        try {
            Communications.makeOAuthRequest(
                _baseUrl + AUTHORIZE_PATH,
                params,
                REDIRECT_URI,
                Communications.OAUTH_RESULT_TYPE_URL,
                {
                    "code" => OAUTH_CODE_KEY,
                    "error" => OAUTH_ERROR_KEY,
                    "state" => OAUTH_STATE_KEY,
                }
            );
        } catch (error) {
            fail("Could not start Dexcom sign-in. Check the phone connection.");
        }
    }

    public function onOAuthMessage(
        message as Communications.OAuthMessage
    ) as Void {
        if (_cancelled || _state != STATE_AUTHORIZE) {
            return;
        }

        if (!(message.data instanceof Lang.Dictionary)) {
            fail("Dexcom sign-in returned no result");
            return;
        }

        var result = message.data as ApiDictionary;
        var returnedState = api.getString(result, OAUTH_STATE_KEY, "");
        var expectedState = BloodSugarStore.getApiAuthorizationState(
            BloodSugarMonitor.DEXCOM,
            _clientId
        );

        if (
            expectedState.length() == 0 ||
            returnedState.length() == 0 ||
            !returnedState.equals(expectedState)
        ) {
            fail("Dexcom sign-in state did not match. Please try again.");
            return;
        }

        BloodSugarStore.clearApiAuthorizationState(BloodSugarMonitor.DEXCOM);
        _oauthState = null;

        var oauthError = api.getString(result, OAUTH_ERROR_KEY, "");
        if (oauthError.length() > 0) {
            if (oauthError.equals("access_denied")) {
                fail("Dexcom access was not approved");
            } else {
                fail("Dexcom sign-in failed: " + oauthError);
            }
            return;
        }

        var authorizationCode = api.getString(result, OAUTH_CODE_KEY, "");
        if (authorizationCode.length() == 0) {
            fail("Dexcom sign-in did not return an authorization code");
            return;
        }

        exchangeAuthorizationCode(authorizationCode);
    }

    private function exchangeAuthorizationCode(code as String) as Void {
        _state = STATE_TOKEN;

        var params =
            ({
                "client_id" => _clientId,
                "client_secret" => _clientSecret,
                "code" => code,
                "grant_type" => "authorization_code",
                "redirect_uri" => REDIRECT_URI,
            }) as Dictionary<Object, Object>;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => ({
                "Content-Type"
                =>
                Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Accept" => "application/json",
            }) as Dictionary<String, String>,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + TOKEN_PATH,
            params,
            options,
            method(:onTokenResponse)
        );
    }

    private function refreshAccessToken() as Void {
        if (_refreshToken == null) {
            fail("Dexcom authorization is missing. Reconnect your account.");
            return;
        }

        _state = STATE_REFRESH;

        var params =
            ({
                "client_id" => _clientId,
                "client_secret" => _clientSecret,
                "refresh_token" => _refreshToken as String,
                "grant_type" => "refresh_token",
            }) as Dictionary<Object, Object>;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => ({
                "Content-Type"
                =>
                Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Accept" => "application/json",
            }) as Dictionary<String, String>,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + TOKEN_PATH,
            params,
            options,
            method(:onTokenResponse)
        );
    }

    public function onTokenResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode != 200) {
            var action =
                _state == STATE_REFRESH ? "refresh authorization" : "sign in";
            if (_state == STATE_REFRESH) {
                clearTokens();
            }
            fail(
                "Could not " +
                    action +
                    " with Dexcom: HTTP " +
                    responseCode.toString()
            );
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Dexcom token response was not a JSON object");
            return;
        }

        var root = response as ApiDictionary;
        var accessToken = api.getString(root, "access_token", "");
        var refreshToken = api.getString(root, "refresh_token", "");
        var expiresIn = api.getNumber(root, "expires_in", 0);

        if (accessToken.length() == 0) {
            fail("Dexcom token response did not contain an access token");
            return;
        }

        if (refreshToken.length() == 0 && _refreshToken != null) {
            refreshToken = _refreshToken as String;
        }

        if (refreshToken.length() == 0) {
            fail("Dexcom token response did not contain a refresh token");
            return;
        }

        var expiresAt = 0;
        if (expiresIn > 0) {
            expiresAt = Time.now().value() + expiresIn;
        }

        if (
            !BloodSugarStore.saveApiTokens(
                BloodSugarMonitor.DEXCOM,
                _clientId,
                _baseUrl,
                accessToken,
                refreshToken,
                expiresAt
            )
        ) {
            fail("Dexcom signed in, but its tokens could not be saved");
            return;
        }

        _bearerToken = accessToken;
        _refreshToken = refreshToken;
        _accessTokenExpiresAt = expiresAt;
        loadDataRange();
    }

    private function loadDataRange() as Void {
        if (_bearerToken == null) {
            fail("Dexcom access token is missing");
            return;
        }

        _state = STATE_DATA_RANGE;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => ({
                "Accept" => "application/json",
                "Authorization" => "Bearer " + (_bearerToken as String),
            }) as Dictionary<String, String>,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + DATA_RANGE_PATH,
            null,
            options,
            method(:onDataRangeResponse)
        );
    }

    public function onDataRangeResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode == 401) {
            if (!_authenticationRetried && _refreshToken != null) {
                _authenticationRetried = true;
                refreshAccessToken();
                return;
            }

            clearTokens();
            fail("Dexcom authorization expired. Reconnect your account.");
            return;
        }

        if (responseCode != 200) {
            fail(
                "Could not load Dexcom data range: " +
                    getResponseCodeText(responseCode)
            );
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Dexcom data-range response was not a JSON object");
            return;
        }

        var root = response as ApiDictionary;
        var egvs = api.getObject(root, "egvs");
        if (egvs == null) {
            complete(0, 0.0, 0);
            return;
        }

        var end = api.getObject(egvs, "end");
        if (end == null) {
            complete(0, 0.0, 0);
            return;
        }

        var latestTimeText = api.getString(end, "systemTime", "");
        var latestTime = parseIso8601(latestTimeText);
        if (latestTime == null) {
            fail("Dexcom data range did not contain a valid EGV end time");
            return;
        }

        /* The end of an EGV query is exclusive, so include one extra second. */
        var queryEnd = (latestTime as Number) + 1;
        loadEgvs(queryEnd - EGV_WINDOW_SECONDS, queryEnd);
    }

    private function loadEgvs(startTime as Number, endTime as Number) as Void {
        if (_bearerToken == null) {
            fail("Dexcom access token is missing");
            return;
        }

        _state = STATE_EGVS;
        System.println(formatUtc(startTime));
        System.println(formatUtc(endTime));
        var params =
            ({
                "startDate" => formatUtc(startTime),
                "endDate" => formatUtc(endTime),
            }) as Dictionary<Object, Object>;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => ({
                "Accept" => "application/json",
                "Authorization" => "Bearer " + (_bearerToken as String),
            }) as Dictionary<String, String>,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        Communications.makeWebRequest(
            _baseUrl + EGVS_PATH,
            params,
            options,
            method(:onEgvsResponse)
        );
    }

    public function onEgvsResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode == 401) {
            if (!_authenticationRetried && _refreshToken != null) {
                _authenticationRetried = true;
                refreshAccessToken();
                return;
            }

            clearTokens();
            fail("Dexcom authorization expired. Reconnect your account.");
            return;
        }

        if (responseCode != 200) {
            fail(
                "Could not load Dexcom readings: " +
                    getResponseCodeText(responseCode)
            );
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Dexcom readings response was not a JSON object");
            return;
        }

        var root = response as ApiDictionary;
        var records = api.getArray(root, "records");
        if (records == null || records.size() == 0) {
            complete(0, 0.0, 0);
            return;
        }

        var readings = [] as Array<BloodSugarReading.IncomingRecord>;
        var latestTimestamp = 0;
        var latestValueMmol = 0.0f;

        for (var index = 0; index < records.size(); index += 1) {
            if (!(records[index] instanceof Lang.Dictionary)) {
                continue;
            }

            var record = records[index] as ApiDictionary;
            var timestampText = api.getString(record, "systemTime", "");
            var valueMgdl = api.getNumber(record, "value", 0);
            var timestamp = parseIso8601(timestampText);

            if (timestamp == null || valueMgdl <= 0) {
                continue;
            }

            var valueMmol = BloodSugarStore.MgdlToMoll(valueMgdl.toFloat());
            readings.add([
                timestamp as Number,
                valueMmol,
                BloodSugarReading.SOURCE_DEXCOM,
                "none",
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

        var addedCount = BloodSugarStore.addReadingsBatch(readings);
        if (addedCount < 0) {
            fail("Dexcom readings were received but could not be stored");
            return;
        }

        complete(latestTimestamp, latestValueMmol, addedCount);
    }

    private function createOAuthState() as String {
        var bytes = Cryptography.randomBytes(16);
        return (
            StringUtil.convertEncodedString(bytes, {
                :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
                :toRepresentation => StringUtil.REPRESENTATION_STRING_HEX,
            }) as String
        );
    }

    private function formatUtc(timestamp as Number) as String {
        var info = Gregorian.utcInfo(
            new Time.Moment(timestamp),
            Time.FORMAT_SHORT
        );

        return (
            info.year.format("%04d") +
            "-" +
            info.month.format("%02d") +
            "-" +
            info.day.format("%02d") +
            "T" +
            info.hour.format("%02d") +
            ":" +
            info.min.format("%02d") +
            ":" +
            info.sec.format("%02d")
        );
    }

    private function parseIso8601(value as String) as Number? {
        if (value.length() < 19) {
            return null;
        }

        if (
            !value.substring(4, 5).equals("-") ||
            !value.substring(7, 8).equals("-") ||
            !value.substring(10, 11).equals("T") ||
            !value.substring(13, 14).equals(":") ||
            !value.substring(16, 17).equals(":")
        ) {
            return null;
        }

        var year = value.substring(0, 4).toNumber();
        var month = value.substring(5, 7).toNumber();
        var day = value.substring(8, 10).toNumber();
        var hour = value.substring(11, 13).toNumber();
        var minute = value.substring(14, 16).toNumber();
        var second = value.substring(17, 19).toNumber();

        if (
            year == null ||
            month == null ||
            day == null ||
            hour == null ||
            minute == null ||
            second == null
        ) {
            return null;
        }

        var timestamp;
        try {
            timestamp = Gregorian.moment({
                :year => year as Number,
                :month => month as Number,
                :day => day as Number,
                :hour => hour as Number,
                :minute => minute as Number,
                :second => second as Number,
            }).value();
        } catch (error) {
            return null;
        }

        var suffix = value.substring(19, value.length());
        var plusPosition = suffix.find("+");
        var minusPosition = suffix.find("-");
        var offsetPosition = plusPosition;
        var offsetDirection = -1;

        if (offsetPosition == null && minusPosition != null) {
            offsetPosition = minusPosition;
            offsetDirection = 1;
        }

        if (offsetPosition == null) {
            return timestamp;
        }

        var offsetText = suffix.substring(
            (offsetPosition as Number) + 1,
            suffix.length()
        );
        var colon = offsetText.find(":");
        if (colon == null || colon < 1 || colon + 2 >= offsetText.length()) {
            return null;
        }

        var offsetHour = offsetText.substring(0, colon as Number).toNumber();
        var offsetMinute = offsetText
            .substring((colon as Number) + 1, (colon as Number) + 3)
            .toNumber();

        if (offsetHour == null || offsetMinute == null) {
            return null;
        }

        var offsetSeconds =
            ((offsetHour as Number) * 60 + (offsetMinute as Number)) * 60;

        return timestamp + offsetDirection * offsetSeconds;
    }

    private function clearTokens() as Void {
        _bearerToken = null;
        _refreshToken = null;
        _accessTokenExpiresAt = 0;
        BloodSugarStore.clearApiTokens(BloodSugarMonitor.DEXCOM);
    }

    private function getResponseCodeText(responseCode as Number) as String {
        if (responseCode == Communications.NETWORK_RESPONSE_TOO_LARGE) {
            return "response was too large for the watch";
        }

        if (responseCode < 0) {
            return "Garmin network error " + responseCode.toString();
        }

        return "HTTP " + responseCode.toString();
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
