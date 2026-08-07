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

module AbbottFreeStyleApiCountries {
    typedef AE as
        interface {
            var lslApi as String;
            var socketHub as String;
        };

    typedef RegionalMap as
        interface {
            var us as AE;
            var eu as AE;
            var fr as AE;
            var jp as AE;
            var de as AE;
            var ap as AE;
            var au as AE;
            var ae as AE;
        };

    typedef Data as
        interface {
            var regionalMap as RegionalMap;
        };

    typedef CountryResponse as
        interface {
            var status as Number;
            var data as Data;
        };

    class AEModel {
        var lslApi as String;
        var socketHub as String;

        public function initialize() {
            lslApi = "";
            socketHub = "";
        }
    }

    class RegionalMapModel {
        var us as AE;
        var eu as AE;
        var fr as AE;
        var jp as AE;
        var de as AE;
        var ap as AE;
        var au as AE;
        var ae as AE;

        public function initialize() {
            us = new AEModel();
            eu = new AEModel();
            fr = new AEModel();
            jp = new AEModel();
            de = new AEModel();
            ap = new AEModel();
            au = new AEModel();
            ae = new AEModel();
        }
    }

    class DataModel {
        var regionalMap as RegionalMap;

        public function initialize() {
            regionalMap = new RegionalMapModel();
        }
    }

    class CountryResponseModel {
        var status as Number;
        var data as Data;

        public function initialize() {
            status = -1;
            data = new DataModel();
        }
    }

    function dictionaryToCountryResponse(
        source as Lang.Dictionary
    ) as CountryResponse? {
        var dataDictionary = dictionaryObject(source, "data");

        if (dataDictionary == null) {
            return null;
        }

        var regionalMapDictionary = dictionaryObject(
            dataDictionary,
            "regionalMap"
        );

        if (regionalMapDictionary == null) {
            return null;
        }

        var result = new CountryResponseModel();
        result.status = dictionaryNumber(source, "status", -1);
        result.data.regionalMap = dictionaryToRegionalMap(
            regionalMapDictionary
        );

        return result;
    }

    function getRegion(regionalMap as RegionalMap, region as String) as AE? {
        if (region.equals("us") || region.equals("US")) {
            return regionalMap.us;
        }

        if (region.equals("eu") || region.equals("EU")) {
            return regionalMap.eu;
        }

        if (region.equals("fr") || region.equals("FR")) {
            return regionalMap.fr;
        }

        if (region.equals("jp") || region.equals("JP")) {
            return regionalMap.jp;
        }

        if (region.equals("de") || region.equals("DE")) {
            return regionalMap.de;
        }

        if (region.equals("ap") || region.equals("AP")) {
            return regionalMap.ap;
        }

        if (region.equals("au") || region.equals("AU")) {
            return regionalMap.au;
        }

        if (region.equals("ae") || region.equals("AE")) {
            return regionalMap.ae;
        }

        return null;
    }

    function getAvailableRegions() as String {
        return "us, eu, fr, jp, de, ap, au, ae";
    }

    function dictionaryToRegionalMap(source as Lang.Dictionary) as RegionalMap {
        var result = new RegionalMapModel();

        result.us = dictionaryToAEOrEmpty(source, "us");
        result.eu = dictionaryToAEOrEmpty(source, "eu");
        result.fr = dictionaryToAEOrEmpty(source, "fr");
        result.jp = dictionaryToAEOrEmpty(source, "jp");
        result.de = dictionaryToAEOrEmpty(source, "de");
        result.ap = dictionaryToAEOrEmpty(source, "ap");
        result.au = dictionaryToAEOrEmpty(source, "au");
        result.ae = dictionaryToAEOrEmpty(source, "ae");

        return result;
    }

    function dictionaryToAEOrEmpty(
        source as Lang.Dictionary,
        key as String
    ) as AE {
        var regionDictionary = dictionaryObject(source, key);

        if (regionDictionary == null) {
            return new AEModel();
        }

        var result = new AEModel();
        result.lslApi = dictionaryString(regionDictionary, "lslApi", "");
        result.socketHub = dictionaryString(regionDictionary, "socketHub", "");

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

        if (value == null) {
            return fallback;
        }

        return value.toString();
    }

    function dictionaryNumber(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Number
    ) as Number {
        var value = dictionaryValue(dictionary, key);

        if (value == null) {
            return fallback;
        }

        return value.toNumber();
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
