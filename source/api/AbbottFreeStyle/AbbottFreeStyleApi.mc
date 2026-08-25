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
import Toybox.Time.Gregorian;

import BloodSugarStore;
import api;

class AbbottFreeStyleApi {
    const DEFAULT_SERVER = "https://api-us.libreview.io";
    const LOGIN_PATH = "/llu/auth/login";
    const CONNECTIONS_PATH = "/llu/connections";
    const COUNTRIES_PATH = "/llu/config/country?country=DE";
    const CLIENT_VERSION = "4.12.0";

    const STATE_IDLE = 0;
    const STATE_LOGIN = 1;
    const STATE_COUNTRIES = 2;
    const STATE_CONNECTIONS = 3;

    private var _email as String;
    private var _password as String;

    private var _baseUrl as String;
    private var _jwtToken as String?;
    private var _accountIdHash as String?;
    private var _redirectRegion as String?;

    private var _state as Number;
    private var _completion as BloodSugarApiReadCallback?;
    private var _authenticationRetried as Boolean;
    private var _cancelled as Boolean;

    public function initialize(email as String, password as String) {
        _email = email;
        _password = password;

        _baseUrl = DEFAULT_SERVER;
        _jwtToken = null;
        _accountIdHash = null;
        _redirectRegion = null;

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

        if (_jwtToken == null || _accountIdHash == null) {
            login();
            return;
        }

        loadConnections();
    }

    private function login() as Void {
        _state = STATE_LOGIN;

        var params =
            ({
                "email" => _email,
                "password" => _password,
            }) as Dictionary<Object, Object>;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => createHeaders(false),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + LOGIN_PATH,
            params,
            options,
            method(:onLoginResponse)
        );
    }

    public function onLoginResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode != 200) {
            fail("Could not login: HTTP " + responseCode.toString());
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Login response was not a JSON object");
            return;
        }

        var root = response as Lang.Dictionary;
        var status = api.getNumber(root, "status", -1);
        var data = api.getObject(root, "data");

        if (status == 2) {
            fail(
                "Bad credentials. Use your LibreLinkUp account " +
                    "credentials, not your LibreLink credentials."
            );
            return;
        }

        if (data == null) {
            fail("Login response did not contain data");
            return;
        }

        if (api.getBoolean(data, "redirect", false)) {
            var region = api.getString(data, "region", "");

            if (region.length() == 0) {
                fail("Regional redirect did not contain a region");
                return;
            }

            _redirectRegion = region;
            loadCountries();
            return;
        }

        /*
         * Status 4 means Abbott requires an additional
         * account action.
         */
        if (status == 4 || data.hasKey("step")) {
            var stepName = "unknown";
            var step = api.getObject(data, "step");

            if (step != null) {
                var componentName = api.getString(step, "componentName", "");

                if (componentName.length() > 0) {
                    stepName = componentName;
                }
            }

            fail(
                "Additional account action required: " +
                    stepName +
                    ". Complete it in LibreLinkUp and try again."
            );

            return;
        }

        if (status != 0) {
            fail("Login response status: " + status.toString());
            return;
        }

        var authTicket = api.getObject(data, "authTicket");
        var user = api.getObject(data, "user");

        if (authTicket == null || user == null) {
            fail("Successful login did not contain authentication data");
            return;
        }

        var token = api.getString(authTicket, "token", "");
        var userId = api.getString(user, "id", "");

        if (token.length() == 0) {
            fail("Login response did not contain an auth token");
            return;
        }

        if (userId.length() == 0) {
            fail("Login response did not contain a user ID");
            return;
        }

        _jwtToken = token;
        _accountIdHash = sha256Hex(userId);
        loadConnections();
    }

    private function loadCountries() as Void {
        _state = STATE_COUNTRIES;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => createHeaders(false),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + COUNTRIES_PATH,
            null,
            options,
            method(:onCountriesResponse)
        );
    }

    public function onCountriesResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode != 200) {
            fail("Could not load countries: HTTP " + responseCode.toString());
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Country response was not a JSON object");
            return;
        }

        if (_redirectRegion == null) {
            fail("Country response received without a redirect");
            return;
        }

        var root = response as Lang.Dictionary;
        var status = api.getNumber(root, "status", -1);

        if (status != 0) {
            fail("Country response status: " + status.toString());
            return;
        }

        var data = api.getObject(root, "data");

        if (data == null) {
            fail("Country response did not contain data");
            return;
        }

        var regionalMap = api.getObject(data, "regionalMap");

        if (regionalMap == null) {
            fail("Country response did not contain a regional map");
            return;
        }

        var region = _redirectRegion as String;
        var regionDefinition = api.getObject(regionalMap, region.toLower());

        if (regionDefinition == null) {
            fail(
                "Unable to find region '" +
                    region +
                    "'. Available nodes: " +
                    "us, eu, fr, jp, de, ap, au, ae"
            );

            return;
        }

        var lslApi = api.getString(regionDefinition, "lslApi", "");

        if (lslApi.length() == 0) {
            fail("Region '" + region + "' did not contain an API URL");

            return;
        }

        _baseUrl = lslApi;
        _redirectRegion = null;
        login();
    }

    private function loadConnections() as Void {
        if (_jwtToken == null || _accountIdHash == null) {
            retryAuthentication("No authentication for connections");

            return;
        }

        _state = STATE_CONNECTIONS;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => createHeaders(true),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + CONNECTIONS_PATH,
            null,
            options,
            method(:onConnectionsResponse)
        );
    }

    public function onConnectionsResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (_cancelled) {
            return;
        }

        if (responseCode == 401 || responseCode == 403) {
            retryAuthentication("Connections authentication failed");

            return;
        }

        if (responseCode != 200) {
            fail("Could not load connections: HTTP " + responseCode.toString());

            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Connections response was not a JSON object");

            return;
        }

        var root = response as Lang.Dictionary;

        var status = api.getNumber(root, "status", -1);

        if (status != 0) {
            fail("Connections response status: " + status.toString());

            return;
        }

        updateTicket(root);
        var connections = api.getArray(root, "data");

        if (connections == null || connections.size() == 0) {
            fail("This LibreLinkUp account does not follow a patient.");

            return;
        }

        if (!(connections[0] instanceof Lang.Dictionary)) {
            fail("The first LibreLinkUp connection was invalid");

            return;
        }

        processCurrentReading(connections[0] as Lang.Dictionary);
    }

    private function processCurrentReading(
        connection as Lang.Dictionary
    ) as Void {
        var currentReading = api.getObject(connection, "glucoseMeasurement");

        if (currentReading == null) {
            complete(0, 0.0, 0);

            return;
        }

        var factoryTimestamp = api.getString(
            currentReading,
            "FactoryTimestamp",
            ""
        );

        var valueMgdl = api.getNumber(currentReading, "ValueInMgPerDl", 0);

        if (factoryTimestamp.length() == 0 || valueMgdl <= 0) {
            complete(0, 0.0, 0);

            return;
        }

        var timestamp = parseFactoryTimestamp(factoryTimestamp);

        if (timestamp == null) {
            fail("Could not parse the LibreLinkUp glucose timestamp");

            return;
        }

        var valueMmol = BloodSugarStore.MgdlToMoll(valueMgdl.toFloat());
        var readings = [[timestamp, valueMmol, "libre_link_up", "none"]];
        var addedCount = BloodSugarStore.addReadingsBatch(readings);

        if (addedCount < 0) {
            fail("Glucose data was received but could not be stored");

            return;
        }

        complete(timestamp, valueMmol, addedCount);
    }

    private function parseFactoryTimestamp(timestamp as String) as Number? {
        var slash1 = timestamp.find("/");

        if (slash1 == null) {
            return null;
        }

        var monthValue = timestamp.toNumber();

        if (monthValue == null) {
            return null;
        }

        var afterMonth = timestamp.substring(slash1 + 1, timestamp.length());

        if (afterMonth == null) {
            return null;
        }

        var slash2 = afterMonth.find("/");

        if (slash2 == null) {
            return null;
        }

        var dayValue = afterMonth.toNumber();

        if (dayValue == null) {
            return null;
        }

        var afterDay = afterMonth.substring(slash2 + 1, afterMonth.length());

        if (afterDay == null) {
            return null;
        }

        var yearValue = afterDay.toNumber();

        var space = afterDay.find(" ");

        if (yearValue == null || space == null) {
            return null;
        }

        var timePart = afterDay.substring(space + 1, afterDay.length());

        if (timePart == null) {
            return null;
        }

        var hourValue = timePart.toNumber();

        var colon1 = timePart.find(":");

        if (hourValue == null || colon1 == null) {
            return null;
        }

        var minutePart = timePart.substring(colon1 + 1, timePart.length());

        if (minutePart == null) {
            return null;
        }

        var minuteValue = minutePart.toNumber();

        var colon2 = minutePart.find(":");

        if (minuteValue == null || colon2 == null) {
            return null;
        }

        var secondPart = minutePart.substring(colon2 + 1, minutePart.length());

        if (secondPart == null) {
            return null;
        }

        var secondValue = secondPart.toNumber();

        if (secondValue == null) {
            return null;
        }

        var month = monthValue as Number;
        var day = dayValue as Number;
        var year = yearValue as Number;
        var hour = hourValue as Number;
        var minute = minuteValue as Number;
        var second = secondValue as Number;

        if (secondPart.find("PM") != null) {
            if (hour < 12) {
                hour += 12;
            }
        } else if (secondPart.find("AM") != null) {
            if (hour == 12) {
                hour = 0;
            }
        } else {
            return null;
        }

        try {
            return Gregorian.moment({
                :year => year,
                :month => month,
                :day => day,
                :hour => hour,
                :minute => minute,
                :second => second,
            }).value();
        } catch (error) {
            return null;
        }
    }

    private function updateTicket(root as Lang.Dictionary) as Void {
        var ticket = api.getObject(root, "ticket");

        if (ticket == null) {
            return;
        }

        var token = api.getString(ticket, "token", "");

        if (token.length() > 0) {
            _jwtToken = token;
        }
    }

    private function createHeaders(
        authenticated as Boolean
    ) as Dictionary<String, String> {
        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Accept" => "application/json",
            "cache-control" => "no-cache",
            "product" => "llu.android",
            "version" => CLIENT_VERSION,
        } as Dictionary<String, String>;

        if (authenticated && _jwtToken != null && _accountIdHash != null) {
            headers["Authorization"] = "Bearer " + (_jwtToken as String);
            headers["account-id"] = _accountIdHash as String;
        }

        return headers;
    }

    private function sha256Hex(value as String) as String {
        var inputBytes =
            StringUtil.convertEncodedString(value, {
                :fromRepresentation
                =>
                StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
                :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
                :encoding => StringUtil.CHAR_ENCODING_UTF8,
            }) as Lang.ByteArray;

        var hash = new Cryptography.Hash({
            :algorithm => Cryptography.HASH_SHA256,
        });

        hash.update(inputBytes);

        var hex =
            StringUtil.convertEncodedString(hash.digest(), {
                :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,

                :toRepresentation => StringUtil.REPRESENTATION_STRING_HEX,
            }) as String;

        return hex.toLower();
    }

    private function retryAuthentication(reason as String) as Void {
        if (_authenticationRetried) {
            fail(reason);
            return;
        }

        _authenticationRetried = true;
        _jwtToken = null;
        _accountIdHash = null;
        _redirectRegion = null;

        login();
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
        System.println("AbbottFreeStyleApi: " + message);

        if (completion != null) {
            completion.invoke(false, 0, 0.0, 0, message);
        }
    }
}
