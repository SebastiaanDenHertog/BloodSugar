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

class xDripApi {
    const STATE_IDLE = 0;
    const STATE_READINGS = 1;

    const READING_MINUTES = 30;
    const READING_MAX_COUNT = 6;

    private var _state as Number;
    private var _cancelled as Boolean;
    private var _completion as BloodSugarApiReadCallback?;
    private var _baseUrl as String;

    public function initialize(server as String) {
        _baseUrl = server;
        _state = STATE_IDLE;
        _cancelled = false;
        _completion = null;
    }

    public function read(completion as BloodSugarApiReadCallback) as Void {
        if (_state != STATE_IDLE) {
            return;
        }

        _completion = completion;
        _cancelled = false;
        loadReadings();
    }

    private function loadReadings() as Void {
        _state = STATE_READINGS;
        var url = _baseUrl + "/sgv.json?count=2&brief_mode=Y";

        Communications.makeWebRequest(
            url,
            ({}) as Dictionary<Object, Object>,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            },
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
            fail(getRequestError("load readings", responseCode, response));
            return;
        }

        if (!(response instanceof Lang.Array)) {
            fail("xdrip Share readings response was not a JSON array");
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
                BloodSugarPackedReading.SOURCE_XDRIP,
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

        var addedCount = BloodSugarBackgroundHistoryStore.addReadings(readings);
        if (addedCount < 0) {
            fail("xdrip+ readings could not be stored");
            return;
        }
        complete(latestTimestamp, latestValueMmol, addedCount);
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

    private function getRequestError(
        action as String,
        responseCode as Number,
        response as Object?
    ) as String {
        if (response instanceof Lang.Dictionary) {
            var error = response as ApiDictionary;
            var code = api.getString(error, "Code", "");
            var message = api.getString(error, "Message", "");

            if (code.length() > 0) {
                return "xdrip+ Share " +
                    code +
                    " (HTTP " +
                    responseCode.toString() +
                    ")";
            }
            if (message.length() > 0) {
                return message +
                    " (HTTP " +
                    responseCode.toString() +
                    ")";
            }
        }

        if (responseCode == Communications.NETWORK_RESPONSE_TOO_LARGE) {
            return "xdrip+ Share response was too large for the watch";
        }
        if (responseCode < 0) {
            return "xdrip+ Garmin network error " + responseCode.toString();
        }
        return (
            "Could not " +
            action +
            " from xdrip+ Share: HTTP " +
            responseCode.toString()
        );
    }

    private function fail(message as String) as Void {
        var completion = _completion;
        _state = STATE_IDLE;
        _completion = null;
        System.println("xDrip: " + message);

        if (completion != null) {
            completion.invoke(false, 0, 0.0, 0, message);
        }
    }

    public function cancel() as Void {
        _cancelled = true;
        _state = STATE_IDLE;
        _completion = null;
        Communications.cancelAllRequests();
    }
}
