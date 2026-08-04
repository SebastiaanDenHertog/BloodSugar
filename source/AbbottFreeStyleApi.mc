import Toybox.Communications;
import Toybox.Cryptography;
import Toybox.Lang;
import Toybox.StringUtil;
import Toybox.System;
import Toybox.Timer;
import AbbottFreeStyleApiLogin;
import AbbottFreeStyleApiCountries;
import AbbottFreeStyleApiConnections;
import AbbottFreeStyleApiGraph;
import BloodSugarStore;
import Toybox.PersistedContent;

class AbbottFreeStyleApi {
    const DEFAULT_SERVER = "https://api-us.libreview.io";
    const LOGIN_PATH = "/llu/auth/login";
    const CONNECTIONS_PATH = "/llu/connections";
    const COUNTRIES_PATH = "/llu/config/country?country=DE";
    const CLIENT_VERSION = "4.12.0";

    const STATE_IDLE = 0;
    const STATE_LOGIN = 1;
    const STATE_CONNECTIONS = 2;
    const STATE_GRAPH = 3;

    private var _email as String;
    private var _password as String;

    private var _baseUrl as String;
    private var _jwtToken as String?;
    private var _accountId as String?;
    private var _patientId as String?;

    private var _state as Number;
    private var _completion;
    private var _authenticationRetried as Boolean;

    private var _redirectResponse as
        AbbottFreeStyleApiLogin.LoginRedirectResponse?;

    private var _pollTimer as Timer.Timer?;
    private var _pollCompletion;

    public function initialize(email as String, password as String) {
        _email = email;
        _password = password;

        _baseUrl = DEFAULT_SERVER;
        _jwtToken = null;
        _accountId = null;
        _patientId = null;

        _state = STATE_IDLE;
        _completion = null;
        _authenticationRetried = false;
        _redirectResponse = null;

        _pollTimer = null;
        _pollCompletion = null;
    }

    public function read(completion) as Void {
        if (_state != STATE_IDLE) {
            return;
        }

        _completion = completion;
        _authenticationRetried = false;

        if (_jwtToken == null || _accountId == null) {
            login();
            return;
        }

        if (_patientId == null) {
            loadConnections();
            return;
        }

        loadGraph();
    }

    public function startPolling(
        intervalMinutes as Number,
        completion
    ) as Void {
        if (intervalMinutes < 1) {
            intervalMinutes = 1;
        }

        stopPolling();

        _pollCompletion = completion;
        _pollTimer = new Timer.Timer();

        read(_pollCompletion);

        _pollTimer.start(
            method(:onPollTimer),
            intervalMinutes * 60 * 1000,
            true
        );
    }

    public function stopPolling() as Void {
        if (_pollTimer != null) {
            _pollTimer.stop();
            _pollTimer = null;
        }

        _pollCompletion = null;
    }

    private function onPollTimer() as Void {
        if (_state == STATE_IDLE && _pollCompletion != null) {
            read(_pollCompletion);
        }
    }

    private function login() as Void {
        _state = STATE_LOGIN;

        var params =
            ({
                "email" => _email,
                "password" => _password,
            }) as Dictionary<Object, Object>;

        var headers = createHeaders(false);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + LOGIN_PATH,
            params,
            options,
            method(:onLoginResponse)
        );
    }

    private function onLoginResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (responseCode != 200) {
            fail("Could not login: HTTP " + responseCode.toString());
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Login response was not a JSON object");
            return;
        }

        var parsedResponse = AbbottFreeStyleApiLogin.dictionaryToLoginResponse(
            response as Lang.Dictionary
        );

        if (parsedResponse == null) {
            fail("Could not map the login response");
            return;
        }

        if (
            parsedResponse instanceof
            AbbottFreeStyleApiLogin.LoginRedirectResponseModel
        ) {
            var redirectResponse =
                parsedResponse as
                AbbottFreeStyleApiLogin.LoginRedirectResponseModel;

            if (!redirectResponse.data.redirect) {
                fail("Invalid regional redirect response");
                return;
            }

            if (redirectResponse.data.region.length() == 0) {
                fail("Regional redirect did not contain a region");
                return;
            }

            _redirectResponse = redirectResponse;
            loadCountries();
            return;
        }

        var loginResponse =
            parsedResponse as AbbottFreeStyleApiLogin.LoginResponseModel;

        if (loginResponse.status == 2) {
            fail(
                "Bad credentials. Use your LibreLinkUp account " +
                    "credentials, not your LibreLink credentials."
            );
            return;
        }

        if (loginResponse.status == 4) {
            var stepName = "unknown";

            if (
                loginResponse.data instanceof
                AbbottFreeStyleApiLogin.StepDataModel
            ) {
                var stepData =
                    loginResponse.data as AbbottFreeStyleApiLogin.StepDataModel;

                if (stepData.step.componentName.length() > 0) {
                    stepName = stepData.step.componentName;
                }
            }

            fail(
                "Additional account action required: " +
                    stepName +
                    ". Complete it in LibreLinkUp and try again."
            );
            return;
        }

        if (
            !(loginResponse.data instanceof AbbottFreeStyleApiLogin.DataModel)
        ) {
            fail("Successful login did not contain login data");
            return;
        }

        var loginData = loginResponse.data as AbbottFreeStyleApiLogin.DataModel;

        if (loginData.authTicket.token.length() == 0) {
            fail("Login response did not contain an auth token");
            return;
        }

        if (loginData.user.id.length() == 0) {
            fail("Login response did not contain a user ID");
            return;
        }

        _jwtToken = loginData.authTicket.token;
        _accountId = loginData.user.id;

        loadConnections();
    }

    private function loadCountries() as Void {
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

    private function onCountriesResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (responseCode != 200) {
            fail("Could not load countries: HTTP " + responseCode.toString());
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Country response was not a JSON object");
            return;
        }

        if (_redirectResponse == null) {
            fail("Country response received without a redirect");
            return;
        }

        var countryResponse =
            AbbottFreeStyleApiCountries.dictionaryToCountryResponse(
                response as Lang.Dictionary
            ) as CountryResponse;

        if (countryResponse == null) {
            fail("Could not map the country response");
            return;
        }

        var regionDefinition = AbbottFreeStyleApiCountries.getRegion(
            countryResponse.data.regionalMap,
            _redirectResponse.data.region
        );

        if (regionDefinition == null || regionDefinition.lslApi.length() == 0) {
            fail(
                "Unable to find region '" +
                    _redirectResponse.data.region +
                    "'. Available nodes: " +
                    AbbottFreeStyleApiCountries.getAvailableRegions()
            );
            return;
        }

        _baseUrl = regionDefinition.lslApi;
        _redirectResponse = null;

        login();
    }

    private function loadConnections() as Void {
        if (_jwtToken == null || _accountId == null) {
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

    private function onConnectionsResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
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

        var connectionsResponse =
            AbbottFreeStyleApiConnections.dictionaryToConnectionsResponse(
                response as Lang.Dictionary
            );

        if (connectionsResponse == null) {
            fail("Could not map the connections response");
            return;
        }

        if (connectionsResponse.status != 0) {
            fail(
                "Connections response status: " +
                    connectionsResponse.status.toString()
            );
            return;
        }

        if (connectionsResponse.data.size() == 0) {
            fail("This LibreLinkUp account does not follow a patient.");
            return;
        }

        var connection = connectionsResponse.data[0];

        if (connection.patientId.length() == 0) {
            fail("The selected connection has no patient ID");
            return;
        }

        _patientId = connection.patientId;

        if (connectionsResponse.ticket.token.length() > 0) {
            _jwtToken = connectionsResponse.ticket.token;
        }

        loadGraph();
    }

    private function loadGraph() as Void {
        if (_patientId == null) {
            loadConnections();
            return;
        }

        if (_jwtToken == null || _accountId == null) {
            retryAuthentication("No authentication for graph request");
            return;
        }

        _state = STATE_GRAPH;

        var graphPath = CONNECTIONS_PATH + "/" + _patientId + "/graph";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => createHeaders(true),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            _baseUrl + graphPath,
            null,
            options,
            method(:onGraphResponse)
        );
    }

    private function onGraphResponse(
        responseCode as Number,
        response as
            Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null
    ) as Void {
        if (responseCode == 401 || responseCode == 403) {
            retryAuthentication("Graph authentication failed");
            return;
        }

        if (responseCode != 200) {
            fail(
                "Could not load glucose graph: HTTP " + responseCode.toString()
            );
            return;
        }

        if (!(response instanceof Lang.Dictionary)) {
            fail("Graph response was not a JSON object");
            return;
        }

        var graphResponse = AbbottFreeStyleApiGraph.dictionaryToGraphData(
            response as Lang.Dictionary
        );

        if (graphResponse == null) {
            fail("Could not map the graph response");
            return;
        }

        if (graphResponse.status != 0) {
            fail("Graph response status: " + graphResponse.status.toString());
            return;
        }

        if (graphResponse.ticket.token.length() > 0) {
            _jwtToken = graphResponse.ticket.token;
        }

        var newReadings = buildStorageReadings(graphResponse);
        var addedCount = BloodSugarStore.addReadingsBatch(newReadings);

        if (addedCount < 0) {
            fail("Glucose data was received but could not be stored");
            return;
        }

        complete(graphResponse.data.connection.glucoseMeasurement, addedCount);
    }

    private function buildStorageReadings(
        graphResponse as AbbottFreeStyleApiGraph.GraphData
    ) {
        var readings = [];

        for (var i = 0; i < graphResponse.data.graphData.size(); i++) {
            addGlucoseItemToStorageBatch(
                graphResponse.data.graphData[i],
                readings
            );
        }

        addGlucoseItemToStorageBatch(
            graphResponse.data.connection.glucoseMeasurement,
            readings
        );

        return readings;
    }

    private function addGlucoseItemToStorageBatch(
        item as GlucoseItem,
        readings
    ) as Void {
        if (
            item.FactoryTimestamp.length() == 0 ||
            item.ValueInMgPerDl <= 0 ||
            item.FactoryTimestamp == null
        ) {
            return;
        }

        var factoryTimestamp = item.FactoryTimestamp;

        if (!(factoryTimestamp instanceof Lang.String)) {
            System.println("FactoryTimestamp was not a string");
            return;
        }

        var timestamp = AbbottFreeStyleApiGraph.parseFactoryTimestamp(
            factoryTimestamp as Lang.String
        );

        if (timestamp == null) {
            System.println("AbbottFreeStyleApi: could not parse timestamp");
            return;
        }

        var valueMmol = BloodSugarStore.MgdlToMoll(
            item.ValueInMgPerDl.toFloat()
        );

        readings.add([timestamp, valueMmol, "libre_link_up", "none"]);
    }

    private function createHeaders(authenticated as Boolean) {
        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Accept" => "application/json",
            "cache-control" => "no-cache",
            "product" => "llu.android",
            "version" => CLIENT_VERSION,
        };

        if (authenticated && _jwtToken != null && _accountId != null) {
            headers["Authorization"] = "Bearer " + _jwtToken;

            headers["account-id"] = sha256Hex(_accountId);
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
        _accountId = null;
        _patientId = null;

        login();
    }

    private function complete(currentReading, addedCount as Number) as Void {
        var completion = _completion;

        _state = STATE_IDLE;
        _completion = null;

        if (completion != null) {
            completion.invoke(true, currentReading, addedCount, "");
        }
    }

    private function fail(message as String) as Void {
        var completion = _completion;

        _state = STATE_IDLE;
        _completion = null;

        System.println("AbbottFreeStyleApi: " + message);

        if (completion != null) {
            completion.invoke(false, null, 0, message);
        }
    }
}
