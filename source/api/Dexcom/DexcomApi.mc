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
import Toybox.Communications;
import Toybox.Cryptography;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.StringUtil;
import Toybox.Time.Gregorian;

import BloodSugarStore;
import api;

class DexcomApi {
    const US_SERVER = "https://sandbox-api.dexcom.com"; //"https://api.dexcom.com";
    const EU_SERVER = "https://api.dexcom.eu";
    const JP_SERVER = "https://api.dexcom.jp";
    const LOGIN_PATH = "/oauth2/login";
    const CLIENT_VERSION = "/v3";

    const STATE_IDLE = 0;
    const STATE_LOGIN = 1;

    private var _client_id as String;
    private var _client_secret as String;

    private var _baseUrl as String;
    private var _bearerToken as String?;
    private var _redirectRegion as String?;

    private var _state as Number;
    private var _authenticationRetried as Boolean;
    private var _cancelled as Boolean;
    private var _completion;

    public function initialize(id as String, secret as String) {
        _client_id = id;
        _client_secret = secret;

        _baseUrl = EU_SERVER;
        _bearerToken = null;
        _redirectRegion = null;

        _state = STATE_IDLE;
        _completion = null;
        _authenticationRetried = false;
        _cancelled = false;
    }

    public function read(completion) as Void {
        if (_state != STATE_IDLE) {
            return;
        }

        _completion = completion;
        _authenticationRetried = false;
        _cancelled = false;

        if (_bearerToken == null) {
            login();
            return;
        }
        loadConnections();
    }

    private function login() as Void {
        _state = STATE_LOGIN;

        var params =
            ({
                "client_id" => _client_id,
                "client_secret" => _client_secret,
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
            fail("Bad credentials. Plz try agian");
            return;
        }

        if (data == null) {
            fail("Login response did not contain data");
            return;
        }
    }

    public function loadConnections() {}

    private function createHeaders(authenticated as Boolean) {
        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Accept" => "application/json",
            "cache-control" => "no-cache",
            "product" => "llu.android",
            "version" => CLIENT_VERSION,
        };

        if (authenticated && _bearerToken != null) {
            headers["Authorization"] = "Bearer " + (_bearerToken as String);
            headers["client-id"] = _client_id as String;
        }

        return headers;
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
