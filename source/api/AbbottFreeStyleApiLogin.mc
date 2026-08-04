import Toybox.Lang;

module AbbottFreeStyleApiLogin {
    typedef LoginArgs as
        interface {
            var username as String;
            var password as String;
        };

    typedef LoginRedirectResponse as
        interface {
            var status as Number;
            var data as LoginRedirectData;
        };

    typedef LoginRedirectData as
        interface {
            var redirect as Boolean;
            var region as String;
        };

    typedef LoginResponse as
        interface {
            var status as Number;
            var data as Data or StepData;
        };

    typedef StepProps as
        interface {
            var email as String;
        };

    typedef StepInfo as
        interface {
            var type as String;
            var componentName as String;
            var props as StepProps;
        };

    typedef StepUser as
        interface {
            var id as String;
            var accountType as String;
            var country as String;
            var uiLanguage as String;
        };

    typedef StepAuthTicket as
        interface {
            var token as String;
            var expires as Number;
            var duration as Number;
        };

    typedef StepData as
        interface {
            var step as StepInfo;
            var user as StepUser;
            var authTicket as StepAuthTicket;
        };

    typedef Data as
        interface {
            var user as User;
            var messages as DataMessages;
            var notifications as Notifications;
            var authTicket as AuthTicket;
            var invitations as Array<String>;
        };

    typedef AuthTicket as
        interface {
            var token as String;
            var expires as Number;
            var duration as Number;
        };

    typedef DataMessages as
        interface {
            var unread as Number;
        };

    typedef Notifications as
        interface {
            var unresolved as Number;
        };

    typedef User as
        interface {
            var id as String;
            var firstName as String;
            var lastName as String;
            var email as String;
            var country as String;
            var uiLanguage as String;
            var communicationLanguage as String;
            var accountType as String;
            var uom as String;
            var dateFormat as String;
            var timeFormat as String;
            var emailDay as Array<Number>;
            var system as System;
            var details as Details;
            var created as Number;
            var lastLogin as Number;
            var programs as Details;
            var dateOfBirth as Number;
            var practices as Details;
            var devices as Details;
            var consents as Consents;
        };

    typedef Consents as
        interface {
            var llu as Llu;
        };

    typedef Llu as
        interface {
            var policyAccept as Number;
            var touAccept as Number;
        };

    typedef Details as Lang.Dictionary;

    typedef System as
        interface {
            var messages as SystemMessages;
        };

    typedef SystemMessages as
        interface {
            var firstUsePhoenix as Number;
            var firstUsePhoenixReportsDataMerged as Number;
            var lluGettingStartedBanner as Number;
            var lluNewFeatureModal as Number;
            var lluOnboarding as Number;
            var lvWebPostRelease as String;
        };

    class LoginRedirectDataModel {
        var redirect as Boolean;
        var region as String;

        public function initialize() {
            redirect = false;
            region = "";
        }
    }

    class LoginRedirectResponseModel {
        var status as Number;
        var data as LoginRedirectData;

        public function initialize(
            responseStatus as Number,
            responseData as LoginRedirectData
        ) {
            status = responseStatus;
            data = responseData;
        }
    }

    class StepPropsModel {
        var email as String;

        public function initialize() {
            email = "";
        }
    }

    class StepInfoModel {
        var type as String;
        var componentName as String;
        var props as StepProps;

        public function initialize() {
            type = "";
            componentName = "";
            props = new StepPropsModel();
        }
    }

    class StepUserModel {
        var id as String;
        var accountType as String;
        var country as String;
        var uiLanguage as String;

        public function initialize() {
            id = "";
            accountType = "";
            country = "";
            uiLanguage = "";
        }
    }

    class StepAuthTicketModel {
        var token as String;
        var expires as Number;
        var duration as Number;

        public function initialize() {
            token = "";
            expires = 0;
            duration = 0;
        }
    }

    class StepDataModel {
        var step as StepInfo;
        var user as StepUser;
        var authTicket as StepAuthTicket;

        public function initialize() {
            step = new StepInfoModel();
            user = new StepUserModel();
            authTicket = new StepAuthTicketModel();
        }
    }

    class AuthTicketModel {
        var token as String;
        var expires as Number;
        var duration as Number;

        public function initialize() {
            token = "";
            expires = 0;
            duration = 0;
        }
    }

    class DataMessagesModel {
        var unread as Number;

        public function initialize() {
            unread = 0;
        }
    }

    class NotificationsModel {
        var unresolved as Number;

        public function initialize() {
            unresolved = 0;
        }
    }

    class LluModel {
        var policyAccept as Number;
        var touAccept as Number;

        public function initialize() {
            policyAccept = 0;
            touAccept = 0;
        }
    }

    class ConsentsModel {
        var llu as Llu;

        public function initialize() {
            llu = new LluModel();
        }
    }

    class SystemMessagesModel {
        var firstUsePhoenix as Number;
        var firstUsePhoenixReportsDataMerged as Number;
        var lluGettingStartedBanner as Number;
        var lluNewFeatureModal as Number;
        var lluOnboarding as Number;
        var lvWebPostRelease as String;

        public function initialize() {
            firstUsePhoenix = 0;
            firstUsePhoenixReportsDataMerged = 0;
            lluGettingStartedBanner = 0;
            lluNewFeatureModal = 0;
            lluOnboarding = 0;
            lvWebPostRelease = "";
        }
    }

    class SystemModel {
        var messages as SystemMessages;

        public function initialize() {
            messages = new SystemMessagesModel();
        }
    }

    class UserModel {
        var id as String;
        var firstName as String;
        var lastName as String;
        var email as String;
        var country as String;
        var uiLanguage as String;
        var communicationLanguage as String;
        var accountType as String;
        var uom as String;
        var dateFormat as String;
        var timeFormat as String;
        var emailDay as Array<Number>;
        var system as System;
        var details as Details;
        var created as Number;
        var lastLogin as Number;
        var programs as Details;
        var dateOfBirth as Number;
        var practices as Details;
        var devices as Details;
        var consents as Consents;

        public function initialize() {
            id = "";
            firstName = "";
            lastName = "";
            email = "";
            country = "";
            uiLanguage = "";
            communicationLanguage = "";
            accountType = "";
            uom = "";
            dateFormat = "";
            timeFormat = "";
            emailDay = [] as Array<Number>;
            system = new SystemModel();
            details = {};
            created = 0;
            lastLogin = 0;
            programs = {};
            dateOfBirth = 0;
            practices = {};
            devices = {};
            consents = new ConsentsModel();
        }
    }

    class DataModel {
        var user as User;
        var messages as DataMessages;
        var notifications as Notifications;
        var authTicket as AuthTicket;
        var invitations as Array<String>;

        public function initialize() {
            user = new UserModel();
            messages = new DataMessagesModel();
            notifications = new NotificationsModel();
            authTicket = new AuthTicketModel();
            invitations = [] as Array<String>;
        }
    }

    class LoginResponseModel {
        var status as Number;
        var data as Data or StepData;

        public function initialize(
            responseStatus as Number,
            responseData as Data or StepData
        ) {
            status = responseStatus;
            data = responseData;
        }
    }

    function dictionaryToLoginResponse(
        source as Lang.Dictionary
    ) as LoginResponse or LoginRedirectResponse or Null {
        var status = dictionaryNumber(source, "status", -1);
        var dataDictionary = dictionaryObject(source, "data");

        if (dataDictionary == null) {
            if (status == 2) {
                return new LoginResponseModel(status, new StepDataModel());
            }

            return null;
        }

        if (dataDictionary.hasKey("redirect")) {
            var redirectData = dictionaryToLoginRedirectData(dataDictionary);

            return new LoginRedirectResponseModel(status, redirectData);
        }

        if (status == 4 || dataDictionary.hasKey("step")) {
            var stepData = dictionaryToStepData(dataDictionary);

            return new LoginResponseModel(status, stepData);
        }
        var loginData = dictionaryToData(dataDictionary);

        return new LoginResponseModel(status, loginData);
    }

    function dictionaryToLoginRedirectData(
        source as Lang.Dictionary
    ) as LoginRedirectData {
        var result = new LoginRedirectDataModel();

        result.redirect = dictionaryBoolean(source, "redirect", false);

        result.region = dictionaryString(source, "region", "");

        return result;
    }

    function dictionaryToStepData(source as Lang.Dictionary) as StepData {
        var result = new StepDataModel();

        var stepDictionary = dictionaryObject(source, "step");
        if (stepDictionary != null) {
            result.step = dictionaryToStepInfo(stepDictionary);
        }

        var userDictionary = dictionaryObject(source, "user");
        if (userDictionary != null) {
            result.user = dictionaryToStepUser(userDictionary);
        }

        var ticketDictionary = dictionaryObject(source, "authTicket");
        if (ticketDictionary != null) {
            result.authTicket = dictionaryToStepAuthTicket(ticketDictionary);
        }

        return result;
    }

    function dictionaryToStepInfo(source as Lang.Dictionary) as StepInfo {
        var result = new StepInfoModel();

        result.type = dictionaryString(source, "type", "");
        result.componentName = dictionaryString(source, "componentName", "");

        var propsDictionary = dictionaryObject(source, "props");
        if (propsDictionary != null) {
            var props = new StepPropsModel();
            props.email = dictionaryString(propsDictionary, "email", "");
            result.props = props;
        }

        return result;
    }

    function dictionaryToStepUser(source as Lang.Dictionary) as StepUser {
        var result = new StepUserModel();

        result.id = dictionaryString(source, "id", "");
        result.accountType = dictionaryString(source, "accountType", "");
        result.country = dictionaryString(source, "country", "");
        result.uiLanguage = dictionaryString(source, "uiLanguage", "");

        return result;
    }

    function dictionaryToStepAuthTicket(
        source as Lang.Dictionary
    ) as StepAuthTicket {
        var result = new StepAuthTicketModel();

        result.token = dictionaryString(source, "token", "");
        result.expires = dictionaryNumber(source, "expires", 0);
        result.duration = dictionaryNumber(source, "duration", 0);

        return result;
    }

    function dictionaryToData(source as Lang.Dictionary) as Data {
        var result = new DataModel();

        var userDictionary = dictionaryObject(source, "user");
        if (userDictionary != null) {
            result.user = dictionaryToUser(userDictionary);
        }

        var messagesDictionary = dictionaryObject(source, "messages");
        if (messagesDictionary != null) {
            result.messages = dictionaryToDataMessages(messagesDictionary);
        }

        var notificationsDictionary = dictionaryObject(source, "notifications");
        if (notificationsDictionary != null) {
            result.notifications = dictionaryToNotifications(
                notificationsDictionary
            );
        }

        var ticketDictionary = dictionaryObject(source, "authTicket");
        if (ticketDictionary != null) {
            result.authTicket = dictionaryToAuthTicket(ticketDictionary);
        }

        result.invitations = dictionaryStringArray(source, "invitations");

        return result;
    }

    function dictionaryToAuthTicket(source as Lang.Dictionary) as AuthTicket {
        var result = new AuthTicketModel();

        result.token = dictionaryString(source, "token", "");
        result.expires = dictionaryNumber(source, "expires", 0);
        result.duration = dictionaryNumber(source, "duration", 0);

        return result;
    }

    function dictionaryToDataMessages(
        source as Lang.Dictionary
    ) as DataMessages {
        var result = new DataMessagesModel();
        result.unread = dictionaryNumber(source, "unread", 0);
        return result;
    }

    function dictionaryToNotifications(
        source as Lang.Dictionary
    ) as Notifications {
        var result = new NotificationsModel();
        result.unresolved = dictionaryNumber(source, "unresolved", 0);
        return result;
    }

    function dictionaryToUser(source as Lang.Dictionary) as User {
        var result = new UserModel();

        result.id = dictionaryString(source, "id", "");
        result.firstName = dictionaryString(source, "firstName", "");
        result.lastName = dictionaryString(source, "lastName", "");
        result.email = dictionaryString(source, "email", "");
        result.country = dictionaryString(source, "country", "");
        result.uiLanguage = dictionaryString(source, "uiLanguage", "");
        result.communicationLanguage = dictionaryString(
            source,
            "communicationLanguage",
            ""
        );
        result.accountType = dictionaryString(source, "accountType", "");
        result.uom = dictionaryString(source, "uom", "");
        result.dateFormat = dictionaryString(source, "dateFormat", "");
        result.timeFormat = dictionaryString(source, "timeFormat", "");
        result.emailDay = dictionaryNumberArray(source, "emailDay");

        var systemDictionary = dictionaryObject(source, "system");
        if (systemDictionary != null) {
            result.system = dictionaryToSystem(systemDictionary);
        }

        result.details = dictionaryObjectOrEmpty(source, "details");
        result.created = dictionaryNumber(source, "created", 0);
        result.lastLogin = dictionaryNumber(source, "lastLogin", 0);
        result.programs = dictionaryObjectOrEmpty(source, "programs");
        result.dateOfBirth = dictionaryNumber(source, "dateOfBirth", 0);
        result.practices = dictionaryObjectOrEmpty(source, "practices");
        result.devices = dictionaryObjectOrEmpty(source, "devices");

        var consentsDictionary = dictionaryObject(source, "consents");
        if (consentsDictionary != null) {
            result.consents = dictionaryToConsents(consentsDictionary);
        }

        return result;
    }

    function dictionaryToSystem(source as Lang.Dictionary) as System {
        var result = new SystemModel();
        var messagesDictionary = dictionaryObject(source, "messages");

        if (messagesDictionary != null) {
            result.messages = dictionaryToSystemMessages(messagesDictionary);
        }

        return result;
    }

    function dictionaryToSystemMessages(
        source as Lang.Dictionary
    ) as SystemMessages {
        var result = new SystemMessagesModel();

        result.firstUsePhoenix = dictionaryNumber(source, "firstUsePhoenix", 0);
        result.firstUsePhoenixReportsDataMerged = dictionaryNumber(
            source,
            "firstUsePhoenixReportsDataMerged",
            0
        );
        result.lluGettingStartedBanner = dictionaryNumber(
            source,
            "lluGettingStartedBanner",
            0
        );
        result.lluNewFeatureModal = dictionaryNumber(
            source,
            "lluNewFeatureModal",
            0
        );
        result.lluOnboarding = dictionaryNumber(source, "lluOnboarding", 0);
        result.lvWebPostRelease = dictionaryString(
            source,
            "lvWebPostRelease",
            ""
        );

        return result;
    }

    function dictionaryToConsents(source as Lang.Dictionary) as Consents {
        var result = new ConsentsModel();
        var lluDictionary = dictionaryObject(source, "llu");

        if (lluDictionary != null) {
            result.llu = dictionaryToLlu(lluDictionary);
        }

        return result;
    }

    function dictionaryToLlu(source as Lang.Dictionary) as Llu {
        var result = new LluModel();

        result.policyAccept = dictionaryNumber(source, "policyAccept", 0);
        result.touAccept = dictionaryNumber(source, "touAccept", 0);

        return result;
    }

    /* -----------------------------------------------------------------
     * Dictionary helpers used only by login mapping
     * ----------------------------------------------------------------- */

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

    function dictionaryBoolean(
        dictionary as Lang.Dictionary,
        key as String,
        fallback as Boolean
    ) as Boolean {
        var value = dictionaryValue(dictionary, key);

        if (value == true) {
            return true;
        }

        if (value == false) {
            return false;
        }

        return fallback;
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

    function dictionaryObjectOrEmpty(
        dictionary as Lang.Dictionary,
        key as String
    ) as Lang.Dictionary {
        var value = dictionaryObject(dictionary, key);

        if (value != null) {
            return value;
        }

        return {};
    }

    function dictionaryNumberArray(
        dictionary as Lang.Dictionary,
        key as String
    ) as Array<Number> {
        var result = [] as Array<Number>;
        var value = dictionaryValue(dictionary, key);

        if (!(value instanceof Lang.Array)) {
            return result;
        }

        var source = value as Lang.Array;

        for (var i = 0; i < source.size(); i++) {
            if (source[i] != null) {
                result.add(source[i].toNumber());
            }
        }

        return result;
    }

    function dictionaryStringArray(
        dictionary as Lang.Dictionary,
        key as String
    ) as Array<String> {
        var result = [] as Array<String>;
        var value = dictionaryValue(dictionary, key);

        if (!(value instanceof Lang.Array)) {
            return result;
        }

        var source = value as Lang.Array;

        for (var i = 0; i < source.size(); i++) {
            if (source[i] != null) {
                result.add(source[i].toString());
            }
        }

        return result;
    }
}
