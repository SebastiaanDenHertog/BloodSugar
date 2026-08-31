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
import Toybox.Lang;

module BloodSugarApiStore {
    const STORAGE_PREFIX = "api.";
    const FIELD_USERNAME = "username";
    const FIELD_PASSWORD = "password";
    const FIELD_SERVER_OWNER = "serverOwner";
    const FIELD_SERVER = "server";
    const FIELD_SESSION_OWNER = "sessionOwner";
    const FIELD_SESSION_SERVER = "sessionServer";
    const FIELD_ACCOUNT_ID = "accountId";
    const FIELD_SESSION_ID = "sessionId";

    function getUsername(monitorId as Number) as String {
        var value = getString(monitorId, FIELD_USERNAME);
        return value == null ? "" : value as String;
    }

    function getPassword(monitorId as Number) as String {
        var value = getString(monitorId, FIELD_PASSWORD);
        return value == null ? "" : value as String;
    }

    function saveCredentials(
        monitorId as Number,
        username as String,
        password as String
    ) as Boolean {
        try {
            write(monitorId, FIELD_USERNAME, username);
            write(monitorId, FIELD_PASSWORD, password);
            return true;
        } catch (error) {
            System.println("Could not save API credentials");
            return false;
        }
    }

    function clearCredentials(monitorId as Number) as Void {
        try {
            remove(monitorId, FIELD_USERNAME);
            remove(monitorId, FIELD_PASSWORD);
        } catch (error) {
            System.println("Could not clear API credentials");
        }
    }

    function getServer(
        monitorId as Number,
        owner as String,
        fallback as String
    ) as String {
        var savedOwner = getString(monitorId, FIELD_SERVER_OWNER);
        var server = getString(monitorId, FIELD_SERVER);
        if (savedOwner != null && server != null && savedOwner == owner) {
            return server as String;
        }
        return fallback;
    }

    function saveServer(
        monitorId as Number,
        owner as String,
        server as String
    ) as Boolean {
        try {
            write(monitorId, FIELD_SERVER_OWNER, owner);
            write(monitorId, FIELD_SERVER, server);
            return true;
        } catch (error) {
            System.println("Could not save API server");
            return false;
        }
    }

    function clearServer(monitorId as Number) as Void {
        try {
            remove(monitorId, FIELD_SERVER_OWNER);
            remove(monitorId, FIELD_SERVER);
        } catch (error) {
            System.println("Could not clear API server");
        }
    }

    function getAccountId(
        monitorId as Number,
        owner as String,
        server as String
    ) as String? {
        return ownsSession(monitorId, owner, server)
            ? getString(monitorId, FIELD_ACCOUNT_ID)
            : null;
    }

    function getSessionId(
        monitorId as Number,
        owner as String,
        server as String
    ) as String? {
        return ownsSession(monitorId, owner, server)
            ? getString(monitorId, FIELD_SESSION_ID)
            : null;
    }

    function saveSession(
        monitorId as Number,
        owner as String,
        server as String,
        accountId as String,
        sessionId as String
    ) as Boolean {
        try {
            write(monitorId, FIELD_SERVER_OWNER, owner);
            write(monitorId, FIELD_SERVER, server);
            write(monitorId, FIELD_SESSION_OWNER, owner);
            write(monitorId, FIELD_SESSION_SERVER, server);
            write(monitorId, FIELD_ACCOUNT_ID, accountId);
            write(monitorId, FIELD_SESSION_ID, sessionId);
            return true;
        } catch (error) {
            System.println("Could not save API session");
            return false;
        }
    }

    function clearSession(monitorId as Number) as Void {
        try {
            remove(monitorId, FIELD_SESSION_OWNER);
            remove(monitorId, FIELD_SESSION_SERVER);
            remove(monitorId, FIELD_ACCOUNT_ID);
            remove(monitorId, FIELD_SESSION_ID);
        } catch (error) {
            System.println("Could not clear API session");
        }
    }

    function ownsSession(
        monitorId as Number,
        owner as String,
        server as String
    ) as Boolean {
        var savedOwner = getString(monitorId, FIELD_SESSION_OWNER);
        var savedServer = getString(monitorId, FIELD_SESSION_SERVER);
        return savedOwner != null &&
            savedServer != null &&
            savedOwner == owner &&
            savedServer == server;
    }

    function key(monitorId as Number, field as String) as String {
        return STORAGE_PREFIX + monitorId.toString() + "." + field;
    }

    function getString(
        monitorId as Number,
        field as String
    ) as String? {
        return BloodSugarSharedStorage.readString(key(monitorId, field));
    }

    function write(
        monitorId as Number,
        field as String,
        value as Object
    ) as Void {
        BloodSugarSharedStorage.writeValue(key(monitorId, field), value);
    }

    function remove(monitorId as Number, field as String) as Void {
        BloodSugarSharedStorage.deleteValue(key(monitorId, field));
    }
}
