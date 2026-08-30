/*
 * Run No Evil tests for pure conversion, context, and API helper behavior.
 */

import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

/* Test.assertEqual's generic SDK signature can trigger Compiler 2 recursion. */
(:typecheck(false))
module BloodSugarUtilityTests {

(:test)
function testBloodSugarUnitConversions(logger as Test.Logger) as Boolean {
    logger.debug("Checking glucose unit conversions");

    var mmol = BloodSugarStore.MgdlToMoll(180.18f);
    var mgdl = BloodSugarStore.MollToMgdl(10.0f);

    Test.assertMessage(
        mmol - 10.0f < 0.001f,
        "180.18 mg/dL should equal 10 mmol/L"
    );
    Test.assertMessage(
        mgdl - 180.18f < 0.01f,
        "10 mmol/L should equal 180.18 mg/dL"
    );
    Test.assertEqual("5.5", BloodSugarStore.formatValue(5.5f, false));
    Test.assertEqual("180", BloodSugarStore.formatValue(10.0f, true));
    Test.assertEqual("mmol/L", BloodSugarStore.getUnitText(false));
    Test.assertEqual("mg/dL", BloodSugarStore.getUnitText(true));

    return true;
}

(:test)
function testBloodSugarContextMappings(logger as Test.Logger) as Boolean {
    logger.debug("Checking context mappings");

    Test.assertEqual(6, BloodSugarStore.normalizeContextIndex(-1));
    Test.assertEqual(0, BloodSugarStore.normalizeContextIndex(7));
    Test.assertEqual(1, BloodSugarStore.getContextIndex("fasting"));
    Test.assertEqual(3, BloodSugarStore.getContextIndex("after_meal"));
    Test.assertEqual(0, BloodSugarStore.getContextIndex("unknown"));
    Test.assertEqual("before_meal", BloodSugarStore.getContextKey(2));
    Test.assertEqual("After exercise", BloodSugarStore.getContextLabel(6));
    Test.assertEqual("none", BloodSugarStore.normalizeContext("invalid"));

    return true;
}

(:test)
function testApiScalarHelpers(logger as Test.Logger) as Boolean {
    logger.debug("Checking scalar API helper values");

    var values =
        ({
            "name" => "Ada",
            "number" => 42,
            "enabled" => true,
            "disabled" => false,
        }) as ApiDictionary;

    Test.assertEqual("Ada", api.getString(values, "name", "fallback"));
    Test.assertEqual("fallback", api.getString(values, "missing", "fallback"));
    Test.assertEqual(42, api.getNumber(values, "number", -1));
    Test.assertEqual(-1, api.getNumber(values, "missing", -1));
    Test.assertEqual(true, api.getBoolean(values, "enabled", false));
    Test.assertEqual(false, api.getBoolean(values, "disabled", true));
    Test.assertEqual(true, api.getBoolean(values, "missing", true));

    return true;
}

(:test)
function testApiCollectionHelpers(logger as Test.Logger) as Boolean {
    logger.debug("Checking collection API helper values");

    var child = ({ "value" => 7 }) as ApiDictionary;
    var items = [1, "two"] as ApiArray;
    var values =
        ({
            "child" => child,
            "items" => items,
            "scalar" => "text",
        }) as ApiDictionary;

    var returnedChild = api.getObject(values, "child");
    var returnedItems = api.getArray(values, "items");

    Test.assertMessage(returnedChild != null, "The child object should load");
    Test.assertMessage(returnedItems != null, "The child array should load");

    if (returnedChild == null || returnedItems == null) {
        return false;
    }

    Test.assertEqual(7, api.getNumber(returnedChild, "value", -1));
    Test.assertEqual(2, returnedItems.size());
    Test.assertEqual(null, api.getObject(values, "scalar"));
    Test.assertEqual(null, api.getArray(values, "scalar"));

    return true;
}

(:test)
function testDexcomApiConstruction(logger as Test.Logger) as Boolean {
    logger.debug("Checking Dexcom API construction");

    var client = new DexcomApi(
        "constructor-test@example.com",
        "password",
        DexcomApi.US_SERVER
    );
    client.cancel();

    return true;
}

(:test)
function testBackgroundHistoryBatchMerge(logger as Test.Logger) as Boolean {
    logger.debug("Checking compact API history merge");

    BloodSugarHistoryStorage.savePacked(
        BloodSugarPackedReading.createHistory(0)
    );
    var readings = [
        [1800000200, 6.2f, BloodSugarPackedReading.SOURCE_DEXCOM, "none"],
        [1800000100, 5.1f, BloodSugarPackedReading.SOURCE_DEXCOM, "none"],
    ] as Array<BloodSugarPackedReading.IncomingRecord>;

    Test.assertEqual(2, BloodSugarBackgroundHistoryStore.addReadings(readings));
    Test.assertEqual(2, BloodSugarHistoryStorage.getCount());
    Test.assertEqual(1800000100, BloodSugarHistoryStorage.getTimeAt(0));
    Test.assertEqual(1800000200, BloodSugarHistoryStorage.getTimeAt(1));
    Test.assertEqual(0, BloodSugarBackgroundHistoryStore.addReadings(readings));

    return true;
}

}
