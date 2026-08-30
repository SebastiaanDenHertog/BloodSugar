/*
 * Run No Evil tests for blood sugar record and packed-history behavior.
 */

import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

/* Test.assertEqual's generic SDK signature can trigger Compiler 2 recursion. */
(:typecheck(false))
module BloodSugarReadingTests {

(:test)
function testBloodSugarReadingCreate(logger as Test.Logger) as Boolean {
    logger.debug("Creating a blood sugar record");

    var reading = BloodSugarReading.create(
        1234567890,
        5.5f,
        BloodSugarReading.SOURCE_MANUAL,
        "fasting"
    );

    Test.assertEqual(1234567890, BloodSugarReading.getTime(reading));
    Test.assertEqual(5.5f, BloodSugarReading.getValueMmol(reading));
    Test.assertEqual(
        BloodSugarReading.SOURCE_MANUAL,
        BloodSugarReading.getSource(reading)
    );
    Test.assertEqual("fasting", BloodSugarReading.getContext(reading));
    Test.assertMessage(
        BloodSugarReading.isCurrent(reading),
        "A newly created record should use the current schema"
    );

    return true;
}

(:test)
function testBloodSugarPackedRoundTrip(logger as Test.Logger) as Boolean {
    logger.debug("Writing and reading packed history");

    var bytes = BloodSugarPackedReading.createHistory(2);
    var wroteFirst = BloodSugarPackedReading.write(
        bytes,
        0,
        1234567890,
        5.67f,
        BloodSugarPackedReading.SOURCE_ID_MANUAL,
        1
    );
    var wroteSecond = BloodSugarPackedReading.write(
        bytes,
        1,
        1234567990,
        12.34f,
        BloodSugarPackedReading.SOURCE_ID_LIBRE_LINK_UP,
        3
    );

    Test.assertMessage(wroteFirst, "The first packed record should be written");
    Test.assertMessage(
        wroteSecond,
        "The second packed record should be written"
    );
    Test.assertEqual(2, BloodSugarPackedReading.getCount(bytes));
    Test.assertEqual(1234567890, BloodSugarPackedReading.getTime(bytes, 0));
    Test.assertEqual(1234567990, BloodSugarPackedReading.getTime(bytes, 1));
    Test.assertMessage(
        Math.abs(BloodSugarPackedReading.getValueMmol(bytes, 0) - 5.67f) <
            0.001f,
        "The first glucose value should survive packing"
    );
    Test.assertMessage(
        Math.abs(BloodSugarPackedReading.getValueMmol(bytes, 1) - 12.34f) <
            0.001f,
        "The second glucose value should survive packing"
    );
    Test.assertEqual(
        BloodSugarPackedReading.SOURCE_ID_MANUAL,
        BloodSugarPackedReading.getSourceIdAt(bytes, 0)
    );
    Test.assertEqual(1, BloodSugarPackedReading.getContextIdAt(bytes, 0));
    Test.assertEqual(
        BloodSugarPackedReading.SOURCE_ID_LIBRE_LINK_UP,
        BloodSugarPackedReading.getSourceIdAt(bytes, 1)
    );
    Test.assertEqual(3, BloodSugarPackedReading.getContextIdAt(bytes, 1));

    return true;
}

(:test)
function testBloodSugarPackedValidation(logger as Test.Logger) as Boolean {
    logger.debug("Checking packed-history validation");

    var bytes = BloodSugarPackedReading.createHistory(1);

    Test.assertMessage(
        BloodSugarPackedReading.isHistory(bytes),
        "A newly allocated packed history should be valid"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.canPackValue(0.0f),
        "Zero is not a valid glucose value"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.canPackValue(-1.0f),
        "Negative glucose values are invalid"
    );
    Test.assertMessage(
        BloodSugarPackedReading.canPackValue(5.5f),
        "A normal glucose value should be packable"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.canPackValue(700.0f),
        "Values larger than the packed representation should be rejected"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.write(
            bytes,
            -1,
            1234567890,
            5.5f,
            0,
            0
        ),
        "A negative record index should be rejected"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.write(bytes, 1, 1234567890, 5.5f, 0, 0),
        "An index beyond the allocated history should be rejected"
    );
    Test.assertMessage(
        !BloodSugarPackedReading.write(bytes, 0, 0, 5.5f, 0, 0),
        "A non-positive timestamp should be rejected"
    );

    return true;
}

(:test)
function testBloodSugarPackedCopy(logger as Test.Logger) as Boolean {
    logger.debug("Copying a packed record");

    var source = BloodSugarPackedReading.createHistory(1);
    var destination = BloodSugarPackedReading.createHistory(1);

    Test.assertMessage(
        BloodSugarPackedReading.write(
            source,
            0,
            1234567890,
            8.25f,
            BloodSugarPackedReading.SOURCE_ID_BLE,
            4
        ),
        "The source record should be written"
    );

    BloodSugarPackedReading.copy(source, 0, destination, 0);

    Test.assertEqual(
        BloodSugarPackedReading.getTime(source, 0),
        BloodSugarPackedReading.getTime(destination, 0)
    );
    Test.assertEqual(
        BloodSugarPackedReading.getValueMmol(source, 0),
        BloodSugarPackedReading.getValueMmol(destination, 0)
    );
    Test.assertEqual(
        BloodSugarPackedReading.getSourceIdAt(source, 0),
        BloodSugarPackedReading.getSourceIdAt(destination, 0)
    );
    Test.assertEqual(
        BloodSugarPackedReading.getContextIdAt(source, 0),
        BloodSugarPackedReading.getContextIdAt(destination, 0)
    );

    return true;
}

(:test)
function testBloodSugarReadingNormalization(logger as Test.Logger) as Boolean {
    logger.debug("Normalizing legacy blood sugar records");

    var legacy = [
        1234567890,
        6.25f,
        BloodSugarReading.SOURCE_BLE,
        "after_meal",
        BloodSugarReading.CURRENT_SCHEMA
    ] as Array<Object?>;
    var normalized = BloodSugarReading.normalize(legacy, 0);

    Test.assertMessage(normalized != null, "A valid legacy record should load");

    if (normalized == null) {
        return false;
    }

    Test.assertEqual(1234567890, BloodSugarReading.getTime(normalized));
    Test.assertEqual(6.25f, BloodSugarReading.getValueMmol(normalized));
    Test.assertEqual(
        BloodSugarReading.SOURCE_BLE,
        BloodSugarReading.getSource(normalized)
    );
    Test.assertEqual("after_meal", BloodSugarReading.getContext(normalized));

    var futureSchema = [
        1234567890,
        6.25f,
        BloodSugarReading.SOURCE_MANUAL,
        "none",
        BloodSugarReading.CURRENT_SCHEMA + 1
    ] as Array<Object?>;

    Test.assertEqual(
        null,
        BloodSugarReading.normalize(futureSchema, 1)
    );
    Test.assertEqual(null, BloodSugarReading.normalize("invalid", 2));

    return true;
}

(:test)
function testBloodSugarSourceMappings(logger as Test.Logger) as Boolean {
    logger.debug("Checking blood sugar source mappings");

    Test.assertEqual(
        BloodSugarPackedReading.SOURCE_ID_MANUAL,
        BloodSugarPackedReading.getSourceId(BloodSugarReading.SOURCE_MANUAL)
    );
    Test.assertEqual(
        BloodSugarPackedReading.SOURCE_ID_LIBRE_LINK_UP,
        BloodSugarPackedReading.getSourceId(BloodSugarReading.SOURCE_LIBRE_LINK_UP)
    );
    Test.assertEqual(
        BloodSugarPackedReading.SOURCE_ID_BLE,
        BloodSugarPackedReading.getSourceId(BloodSugarReading.SOURCE_BLE)
    );
    Test.assertEqual(
        BloodSugarReading.SOURCE_UNKNOWN,
        BloodSugarPackedReading.getSource(99)
    );

    return true;
}

}
