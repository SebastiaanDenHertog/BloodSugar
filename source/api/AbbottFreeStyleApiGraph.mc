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

And 

MIT License

Copyright (c) 2022 DiaKEM Dexcom Api Client

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
import Toybox.Time;
import Toybox.Time.Gregorian;

module AbbottFreeStyleApiGraph {
    typedef GraphData as
        interface {
            var status as Number;
            var data as Data;
            var ticket as Ticket;
        };

    typedef Data as
        interface {
            var connection as Connection;
            var activeSensors as Array<ActiveSensor>;
            var graphData as Array<GlucoseItem>;
        };

    typedef ActiveSensor as
        interface {
            var sensor as Sensor;
            var device as Device;
        };

    typedef Device as
        interface {
            var did as String;
            var dtid as Number;
            var v as String;
            var ll as Number;
            var hl as Number;
            var u as Number;
            var fixedLowAlarmValues as FixedLowAlarmValues;
            var alarms as Boolean;
        };

    typedef FixedLowAlarmValues as
        interface {
            var mgdl as Number;
            var mmoll as Number;
        };

    typedef Sensor as
        interface {
            var deviceId as String;
            var sn as String;
            var a as Number;
            var w as Number;
            var pt as Number;
        };

    typedef Connection as
        interface {
            var id as String;
            var patientId as String;
            var country as String;
            var status as Number;
            var firstName as String;
            var lastName as String;
            var targetLow as Number;
            var targetHigh as Number;
            var uom as Number;
            var sensor as Sensor;
            var alarmRules as AlarmRules;
            var glucoseMeasurement as GlucoseItem;
            var glucoseItem as GlucoseItem;
            var glucoseAlarm as Null;
            var patientDevice as Device;
            var created as Number;
        };

    typedef AlarmRules as
        interface {
            var c as Boolean;
            var h as H;
            var f as F;
            var l as F;
            var nd as Nd;
            var p as Number;
            var r as Number;
            var std as Std;
        };

    typedef F as
        interface {
            var th as Number;
            var thmm as Number;
            var d as Number;
            var tl as Number;
            var tlmm as Number;
            var on as Boolean?;
        };

    typedef H as
        interface {
            var on as Boolean;
            var th as Number;
            var thmm as Number;
            var d as Number;
            var f as Number;
        };

    typedef Nd as
        interface {
            var i as Number;
            var r as Number;
            var l as Number;
        };

    typedef Std as Lang.Dictionary;

    typedef GlucoseItem as
        interface {
            var FactoryTimestamp as String;
            var Timestamp as String;
            var type as Number;
            var ValueInMgPerDl as Number;
            var TrendArrow as Number?;
            var TrendMessage as Null;
            var MeasurementColor as Number;
            var GlucoseUnits as Number;
            var Value as Number;
            var isHigh as Boolean;
            var isLow as Boolean;
        };

    typedef Ticket as
        interface {
            var token as String;
            var expires as Number;
            var duration as Number;
        };

    class GraphDataModel {
        var status as Number;
        var data as Data;
        var ticket as Ticket;

        public function initialize() {
            status = -1;
            data = new DataModel();
            ticket = new TicketModel();
        }
    }

    class DataModel {
        var connection as Connection;
        var activeSensors as Array<ActiveSensor>;
        var graphData as Array<GlucoseItem>;

        public function initialize() {
            connection = new ConnectionModel();
            activeSensors = [] as Array<ActiveSensor>;
            graphData = [] as Array<GlucoseItem>;
        }
    }

    class ActiveSensorModel {
        var sensor as Sensor;
        var device as Device;

        public function initialize() {
            sensor = new SensorModel();
            device = new DeviceModel();
        }
    }

    class DeviceModel {
        var did as String;
        var dtid as Number;
        var v as String;
        var ll as Number;
        var hl as Number;
        var u as Number;
        var fixedLowAlarmValues as FixedLowAlarmValues;
        var alarms as Boolean;

        public function initialize() {
            did = "";
            dtid = 0;
            v = "";
            ll = 0;
            hl = 0;
            u = 0;
            fixedLowAlarmValues = new FixedLowAlarmValuesModel();
            alarms = false;
        }
    }

    class FixedLowAlarmValuesModel {
        var mgdl as Number;
        var mmoll as Number;

        public function initialize() {
            mgdl = 0;
            mmoll = 0;
        }
    }

    class SensorModel {
        var deviceId as String;
        var sn as String;
        var a as Number;
        var w as Number;
        var pt as Number;

        public function initialize() {
            deviceId = "";
            sn = "";
            a = 0;
            w = 0;
            pt = 0;
        }
    }

    class ConnectionModel {
        var id as String;
        var patientId as String;
        var country as String;
        var status as Number;
        var firstName as String;
        var lastName as String;
        var targetLow as Number;
        var targetHigh as Number;
        var uom as Number;
        var sensor as Sensor;
        var alarmRules as AlarmRules;
        var glucoseMeasurement as GlucoseItem;
        var glucoseItem as GlucoseItem;
        var glucoseAlarm as Null;
        var patientDevice as Device;
        var created as Number;

        public function initialize() {
            id = "";
            patientId = "";
            country = "";
            status = 0;
            firstName = "";
            lastName = "";
            targetLow = 0;
            targetHigh = 0;
            uom = 0;
            sensor = new SensorModel();
            alarmRules = new AlarmRulesModel();
            glucoseMeasurement = new GlucoseItemModel();
            glucoseItem = new GlucoseItemModel();
            glucoseAlarm = null;
            patientDevice = new DeviceModel();
            created = 0;
        }
    }

    class AlarmRulesModel {
        var c as Boolean;
        var h as H;
        var f as F;
        var l as F;
        var nd as Nd;
        var p as Number;
        var r as Number;
        var std as Std;

        public function initialize() {
            c = false;
            h = new HModel();
            f = new FModel();
            l = new FModel();
            nd = new NdModel();
            p = 0;
            r = 0;
            std = new StdModel();
        }
    }

    class FModel {
        var th as Number;
        var thmm as Number;
        var d as Number;
        var tl as Number;
        var tlmm as Number;
        var on as Boolean?;

        public function initialize() {
            th = 0;
            thmm = 0;
            d = 0;
            tl = 0;
            tlmm = 0;
            on = null;
        }
    }

    class HModel {
        var on as Boolean;
        var th as Number;
        var thmm as Number;
        var d as Number;
        var f as Number;

        public function initialize() {
            on = false;
            th = 0;
            thmm = 0;
            d = 0;
            f = 0;
        }
    }

    class NdModel {
        var i as Number;
        var r as Number;
        var l as Number;

        public function initialize() {
            i = 0;
            r = 0;
            l = 0;
        }
    }

    class StdModel {
        public function initialize() {}
    }

    class GlucoseItemModel {
        var FactoryTimestamp as String;
        var Timestamp as String;
        var type as Number;
        var ValueInMgPerDl as Number;
        var TrendArrow as Number?;
        var TrendMessage as Null;
        var MeasurementColor as Number;
        var GlucoseUnits as Number;
        var Value as Number;
        var isHigh as Boolean;
        var isLow as Boolean;

        public function initialize() {
            FactoryTimestamp = "";
            Timestamp = "";
            type = 0;
            ValueInMgPerDl = 0;
            TrendArrow = null;
            TrendMessage = null;
            MeasurementColor = 0;
            GlucoseUnits = 0;
            Value = 0;
            isHigh = false;
            isLow = false;
        }
    }

    class TicketModel {
        var token as String;
        var expires as Number;
        var duration as Number;

        public function initialize() {
            token = "";
            expires = 0;
            duration = 0;
        }
    }

    function dictionaryToGraphData(source as Lang.Dictionary) as GraphData? {
        var dataDictionary = dictionaryObject(source, "data");

        if (dataDictionary == null) {
            return null;
        }

        var connectionDictionary = dictionaryObject(
            dataDictionary,
            "connection"
        );

        if (connectionDictionary == null) {
            return null;
        }

        var result = new GraphDataModel();
        result.status = dictionaryNumber(source, "status", -1);
        result.data.connection = dictionaryToConnection(connectionDictionary);

        var graphDataValue = dictionaryValue(dataDictionary, "graphData");
        if (graphDataValue instanceof Lang.Array) {
            var graphArray = graphDataValue as Lang.Array;
            var mappedGraph = [] as Array<GlucoseItem>;

            for (var i = 0; i < graphArray.size(); i++) {
                if (graphArray[i] instanceof Lang.Dictionary) {
                    mappedGraph.add(
                        dictionaryToGlucoseItem(
                            graphArray[i] as Lang.Dictionary
                        )
                    );
                }
            }

            result.data.graphData = mappedGraph;
        }

        var activeSensorsValue = dictionaryValue(
            dataDictionary,
            "activeSensors"
        );
        if (activeSensorsValue instanceof Lang.Array) {
            var sensorArray = activeSensorsValue as Lang.Array;
            var mappedSensors = [] as Array<ActiveSensor>;

            for (var j = 0; j < sensorArray.size(); j++) {
                if (sensorArray[j] instanceof Lang.Dictionary) {
                    mappedSensors.add(
                        dictionaryToActiveSensor(
                            sensorArray[j] as Lang.Dictionary
                        )
                    );
                }
            }

            result.data.activeSensors = mappedSensors;
        }

        var ticketDictionary = dictionaryObject(source, "ticket");
        if (ticketDictionary != null) {
            result.ticket = dictionaryToTicket(ticketDictionary);
        }

        return result;
    }

    function parseFactoryTimestamp(timestamp as String) as Number? {
        /* LibreLinkUp example: 5/21/2022 1:38:50 PM */
        var parts = splitString(timestamp, " ");

        if (parts.size() < 3) {
            return null;
        }

        var dateParts = splitString(parts[0], "/");
        var timeParts = splitString(parts[1], ":");

        if (dateParts.size() != 3 || timeParts.size() != 3) {
            return null;
        }

        var month = dateParts[0].toNumber();
        var day = dateParts[1].toNumber();
        var year = dateParts[2].toNumber();
        var hour = timeParts[0].toNumber();
        var minute = timeParts[1].toNumber();
        var second = timeParts[2].toNumber();
        var period = parts[2];

        if (period.equals("AM") && hour == 12) {
            hour = 0;
        } else if (period.equals("PM") && hour < 12) {
            hour += 12;
        }

        try {
            var moment = Gregorian.moment({
                :year => year,
                :month => month,
                :day => day,
                :hour => hour,
                :minute => minute,
                :second => second,
            });

            return moment.value();
        } catch (error) {
            return null;
        }
    }

    function dictionaryToActiveSensor(
        source as Lang.Dictionary
    ) as ActiveSensor {
        var result = new ActiveSensorModel();

        var sensor = dictionaryObject(source, "sensor");
        if (sensor != null) {
            result.sensor = dictionaryToSensor(sensor);
        }

        var device = dictionaryObject(source, "device");
        if (device != null) {
            result.device = dictionaryToDevice(device);
        }

        return result;
    }

    function dictionaryToConnection(source as Lang.Dictionary) as Connection {
        var result = new ConnectionModel();
        result.id = dictionaryString(source, "id", "");
        result.patientId = dictionaryString(source, "patientId", "");
        result.country = dictionaryString(source, "country", "");
        result.status = dictionaryNumber(source, "status", 0);
        result.firstName = dictionaryString(source, "firstName", "");
        result.lastName = dictionaryString(source, "lastName", "");
        result.targetLow = dictionaryNumber(source, "targetLow", 0);
        result.targetHigh = dictionaryNumber(source, "targetHigh", 0);
        result.uom = dictionaryNumber(source, "uom", 0);
        result.created = dictionaryNumber(source, "created", 0);

        var sensor = dictionaryObject(source, "sensor");
        if (sensor != null) {
            result.sensor = dictionaryToSensor(sensor);
        }

        var alarmRules = dictionaryObject(source, "alarmRules");
        if (alarmRules != null) {
            result.alarmRules = dictionaryToAlarmRules(alarmRules);
        }

        var glucoseMeasurement = dictionaryObject(source, "glucoseMeasurement");
        if (glucoseMeasurement != null) {
            result.glucoseMeasurement =
                dictionaryToGlucoseItem(glucoseMeasurement);
        }

        var glucoseItem = dictionaryObject(source, "glucoseItem");
        if (glucoseItem != null) {
            result.glucoseItem = dictionaryToGlucoseItem(glucoseItem);
        }

        var patientDevice = dictionaryObject(source, "patientDevice");
        if (patientDevice != null) {
            result.patientDevice = dictionaryToDevice(patientDevice);
        }

        return result;
    }

    function dictionaryToAlarmRules(source as Lang.Dictionary) as AlarmRules {
        var result = new AlarmRulesModel();
        result.c = dictionaryBoolean(source, "c", false);
        result.p = dictionaryNumber(source, "p", 0);
        result.r = dictionaryNumber(source, "r", 0);

        var h = dictionaryObject(source, "h");
        if (h != null) {
            result.h = dictionaryToH(h);
        }

        var f = dictionaryObject(source, "f");
        if (f != null) {
            result.f = dictionaryToF(f);
        }

        var l = dictionaryObject(source, "l");
        if (l != null) {
            result.l = dictionaryToF(l);
        }

        var nd = dictionaryObject(source, "nd");
        if (nd != null) {
            result.nd = dictionaryToNd(nd);
        }

        return result;
    }

    function dictionaryToF(source as Lang.Dictionary) as F {
        var result = new FModel();
        result.th = dictionaryNumber(source, "th", 0);
        result.thmm = dictionaryNumber(source, "thmm", 0);
        result.d = dictionaryNumber(source, "d", 0);
        result.tl = dictionaryNumber(source, "tl", 0);
        result.tlmm = dictionaryNumber(source, "tlmm", 0);

        if (source.hasKey("on") && source["on"] != null) {
            result.on = source["on"] == true;
        }

        return result;
    }

    function dictionaryToH(source as Lang.Dictionary) as H {
        var result = new HModel();
        result.on = dictionaryBoolean(source, "on", false);
        result.th = dictionaryNumber(source, "th", 0);
        result.thmm = dictionaryNumber(source, "thmm", 0);
        result.d = dictionaryNumber(source, "d", 0);
        result.f = dictionaryNumber(source, "f", 0);
        return result;
    }

    function dictionaryToNd(source as Lang.Dictionary) as Nd {
        var result = new NdModel();
        result.i = dictionaryNumber(source, "i", 0);
        result.r = dictionaryNumber(source, "r", 0);
        result.l = dictionaryNumber(source, "l", 0);
        return result;
    }

    function dictionaryToGlucoseItem(source as Lang.Dictionary) as GlucoseItem {
        var result = new GlucoseItemModel();
        result.FactoryTimestamp = dictionaryString(
            source,
            "FactoryTimestamp",
            ""
        );
        result.Timestamp = dictionaryString(source, "Timestamp", "");
        result.type = dictionaryNumber(source, "type", 0);
        result.ValueInMgPerDl = dictionaryNumber(source, "ValueInMgPerDl", 0);

        if (source.hasKey("TrendArrow") && source["TrendArrow"] != null) {
            result.TrendArrow = source["TrendArrow"].toNumber();
        }

        result.MeasurementColor = dictionaryNumber(
            source,
            "MeasurementColor",
            0
        );
        result.GlucoseUnits = dictionaryNumber(source, "GlucoseUnits", 0);
        result.Value = dictionaryNumber(source, "Value", 0);
        result.isHigh = dictionaryBoolean(source, "isHigh", false);
        result.isLow = dictionaryBoolean(source, "isLow", false);
        return result;
    }

    function dictionaryToDevice(source as Lang.Dictionary) as Device {
        var result = new DeviceModel();
        result.did = dictionaryString(source, "did", "");
        result.dtid = dictionaryNumber(source, "dtid", 0);
        result.v = dictionaryString(source, "v", "");
        result.ll = dictionaryNumber(source, "ll", 0);
        result.hl = dictionaryNumber(source, "hl", 0);
        result.u = dictionaryNumber(source, "u", 0);
        result.alarms = dictionaryBoolean(source, "alarms", false);

        var fixedLow = dictionaryObject(source, "fixedLowAlarmValues");
        if (fixedLow != null) {
            result.fixedLowAlarmValues = dictionaryToFixedLow(fixedLow);
        }

        return result;
    }

    function dictionaryToFixedLow(
        source as Lang.Dictionary
    ) as FixedLowAlarmValues {
        var result = new FixedLowAlarmValuesModel();
        result.mgdl = dictionaryNumber(source, "mgdl", 0);
        result.mmoll = dictionaryNumber(source, "mmoll", 0);
        return result;
    }

    function dictionaryToSensor(source as Lang.Dictionary) as Sensor {
        var result = new SensorModel();
        result.deviceId = dictionaryString(source, "deviceId", "");
        result.sn = dictionaryString(source, "sn", "");
        result.a = dictionaryNumber(source, "a", 0);
        result.w = dictionaryNumber(source, "w", 0);
        result.pt = dictionaryNumber(source, "pt", 0);
        return result;
    }

    function dictionaryToTicket(source as Lang.Dictionary) as Ticket {
        var result = new TicketModel();
        result.token = dictionaryString(source, "token", "");
        result.expires = dictionaryNumber(source, "expires", 0);
        result.duration = dictionaryNumber(source, "duration", 0);
        return result;
    }

    function splitString(
        value as String,
        separator as String
    ) as Array<String> {
        var result = [] as Array<String>;
        var remaining = value;

        while (true) {
            var index = remaining.find(separator);

            if (index == null) {
                result.add(remaining);
                break;
            }

            var part = remaining.substring(0, index);
            result.add(part == null ? "" : part);

            var tail = remaining.substring(index + separator.length(), null);
            remaining = tail == null ? "" : tail;
        }

        return result;
    }

    function dictionaryValue(dictionary as Lang.Dictionary, key as String) {
        if (dictionary.hasKey(key) && dictionary[key] != null) {
            return dictionary[key];
        }

        return null;
    }

    function dictionaryString(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as String
    ) as String {
        var value = dictionaryValue(dictionary, key);
        return value == null ? fallback : value.toString();
    }

    function dictionaryNumber(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Number
    ) as Number {
        var value = dictionaryValue(dictionary, key);
        return value == null ? fallback : value.toNumber();
    }

    function dictionaryBoolean(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Boolean
    ) as Boolean {
        var value = dictionaryValue(dictionary, key);
        return value == null ? fallback : value == true;
    }

    function dictionaryObject(
        dictionary as Lang.Dictionary,
        key as String
    ) as Lang.Dictionary? {
        var value = dictionaryValue(dictionary, key);

        if (value instanceof Lang.Dictionary) {
            return value as Lang.Dictionary;
        }

        return null;
    }
}
