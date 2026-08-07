/*
 * Host unit tests for the daylight-saving rules in src/Dst.cpp.
 *
 * These run on your computer, so a transition can be checked without waiting
 * for March:
 *   pio test -e native
 *
 * All times passed to isDstActive() are LOCAL STANDARD time, which is what the
 * DS3231 stores. Transition instants are verified from both sides - the minute
 * before and the minute of - because an off-by-one-hour rule is the easiest
 * mistake to make here and the hardest to notice until the day itself.
 */

#include <unity.h>

#include "Dst.h"

// ---- Calendar helpers -------------------------------------------------------

void test_days_in_month_leap_years(void) {
  TEST_ASSERT_EQUAL_UINT8(28, daysInMonth(2026, 2));
  TEST_ASSERT_EQUAL_UINT8(29, daysInMonth(2024, 2));  // divisible by 4
  TEST_ASSERT_EQUAL_UINT8(28, daysInMonth(1900, 2));  // century, not leap
  TEST_ASSERT_EQUAL_UINT8(29, daysInMonth(2000, 2));  // 400-year exception
  TEST_ASSERT_EQUAL_UINT8(31, daysInMonth(2026, 1));
  TEST_ASSERT_EQUAL_UINT8(30, daysInMonth(2026, 4));
  // Out of range must be safe, never 0.
  TEST_ASSERT_EQUAL_UINT8(31, daysInMonth(2026, 0));
  TEST_ASSERT_EQUAL_UINT8(31, daysInMonth(2026, 13));
}

void test_days_from_civil_epoch(void) {
  TEST_ASSERT_EQUAL_INT32(0, daysFromCivil(1970, 1, 1));
  TEST_ASSERT_EQUAL_INT32(1, daysFromCivil(1970, 1, 2));
  TEST_ASSERT_EQUAL_INT32(365, daysFromCivil(1971, 1, 1));
  // 2000-01-01 is 10957 days after the epoch (RTClib's own constant / 86400).
  TEST_ASSERT_EQUAL_INT32(10957, daysFromCivil(2000, 1, 1));
  // Leap day arithmetic across the March boundary.
  TEST_ASSERT_EQUAL_INT32(daysFromCivil(2024, 2, 29) + 1,
                          daysFromCivil(2024, 3, 1));
}

void test_weekday_known_dates(void) {
  TEST_ASSERT_EQUAL_UINT8(4, weekdayOf(1970, 1, 1));   // Thursday
  TEST_ASSERT_EQUAL_UINT8(6, weekdayOf(2000, 1, 1));   // Saturday
  TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(2026, 3, 29));  // Sunday
  TEST_ASSERT_EQUAL_UINT8(1, weekdayOf(2026, 3, 30));  // Monday
  TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(2024, 11, 3));  // Sunday
}

void test_nth_weekday_of_month(void) {
  // March 2026: Sundays fall on 1, 8, 15, 22, 29.
  TEST_ASSERT_EQUAL_UINT8(1, nthWeekdayOfMonth(2026, 3, 0, 1));
  TEST_ASSERT_EQUAL_UINT8(8, nthWeekdayOfMonth(2026, 3, 0, 2));
  TEST_ASSERT_EQUAL_UINT8(29, nthWeekdayOfMonth(2026, 3, 0, 5));
  TEST_ASSERT_EQUAL_UINT8(29, nthWeekdayOfMonth(2026, 3, 0, -1));  // last

  // A month whose first day IS the target weekday must not skip a week.
  TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(2026, 3, 1));

  // February 2026 starts on a Sunday and has only four Sundays (1,8,15,22),
  // so a fifth does not exist.
  TEST_ASSERT_EQUAL_UINT8(22, nthWeekdayOfMonth(2026, 2, 0, 4));
  TEST_ASSERT_EQUAL_UINT8(0, nthWeekdayOfMonth(2026, 2, 0, 5));

  // Last Sunday of October 2026 is the 25th.
  TEST_ASSERT_EQUAL_UINT8(25, nthWeekdayOfMonth(2026, 10, 0, -1));
  // Bad input is rejected rather than returning a plausible-looking day.
  TEST_ASSERT_EQUAL_UINT8(0, nthWeekdayOfMonth(2026, 13, 0, 1));
  TEST_ASSERT_EQUAL_UINT8(0, nthWeekdayOfMonth(2026, 3, 9, 1));
}

// ---- Off means never shift --------------------------------------------------

void test_off_never_shifts(void) {
  // Mid-summer in both hemispheres, and on a transition day itself.
  TEST_ASSERT_FALSE(isDstActive(DstZone::Off, 2026, 7, 1, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(DstZone::Off, 2026, 1, 1, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(DstZone::Off, 2026, 3, 29, 2, 0));
  TEST_ASSERT_EQUAL_UINT8(0, dstOffsetMinutes(DstZone::Off, 2026, 7, 1, 12, 0));
}

// ---- Europe ----------------------------------------------------------------

void test_europe_west_2026(void) {
  const DstZone z = DstZone::EuropeWest;
  // Starts last Sunday in March 2026 (the 29th) at 01:00 GMT.
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 3, 29, 0, 59));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 3, 29, 1, 0));
  // Ends last Sunday in October 2026 (the 25th) at 02:00 BST = 01:00 GMT.
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 10, 25, 0, 59));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 10, 25, 1, 0));
  // Deep summer and deep winter.
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 7, 15, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 12, 25, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 1, 15, 12, 0));
  TEST_ASSERT_EQUAL_UINT8(60, dstOffsetMinutes(z, 2026, 7, 15, 12, 0));
}

void test_europe_central_2026(void) {
  const DstZone z = DstZone::EuropeCentral;
  // Same instant as the UK, but CET is UTC+1 so it is an hour later locally:
  // 02:00 CET -> 03:00 CEST.
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 3, 29, 1, 59));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 3, 29, 2, 0));
  // Ends 03:00 CEST = 02:00 CET.
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 10, 25, 1, 59));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 10, 25, 2, 0));
}

void test_europe_east_2026(void) {
  const DstZone z = DstZone::EuropeEast;
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 3, 29, 2, 59));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 3, 29, 3, 0));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 10, 25, 2, 59));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 10, 25, 3, 0));
}

void test_europe_across_several_years(void) {
  const DstZone z = DstZone::EuropeCentral;
  // Last Sunday in March / October for each year, checked from the rule rather
  // than hard-coded, then probed either side of the transition.
  const uint16_t years[] = {2024, 2025, 2026, 2027, 2030, 2036};
  for (unsigned i = 0; i < sizeof(years) / sizeof(years[0]); i++) {
    const uint16_t y = years[i];
    const uint8_t mar = nthWeekdayOfMonth(y, 3, 0, -1);
    const uint8_t oct = nthWeekdayOfMonth(y, 10, 0, -1);
    TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(y, 3, mar));   // really a Sunday
    TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(y, 10, oct));
    TEST_ASSERT_TRUE(mar >= 25);  // "last Sunday" is always in the final week
    TEST_ASSERT_TRUE(oct >= 25);

    TEST_ASSERT_FALSE(isDstActive(z, y, 3, mar, 1, 59));
    TEST_ASSERT_TRUE(isDstActive(z, y, 3, mar, 2, 0));
    TEST_ASSERT_TRUE(isDstActive(z, y, 10, oct, 1, 59));
    TEST_ASSERT_FALSE(isDstActive(z, y, 10, oct, 2, 0));
    // Either side of each transition, well clear of the boundary hour. The
    // "after" probes use a fixed mid-month date rather than transition+1,
    // because the last Sunday of March or October can be the 31st (2024, 2027)
    // and there is no 32nd.
    TEST_ASSERT_FALSE(isDstActive(z, y, 3, mar - 1, 12, 0));
    TEST_ASSERT_TRUE(isDstActive(z, y, 4, 15, 12, 0));
    TEST_ASSERT_TRUE(isDstActive(z, y, 10, oct - 1, 12, 0));
    TEST_ASSERT_FALSE(isDstActive(z, y, 11, 15, 12, 0));
  }
}

// ---- North America ---------------------------------------------------------

void test_north_america_2026(void) {
  const DstZone z = DstZone::NorthAmerica;
  // Starts the second Sunday in March 2026 = the 8th, at 02:00 standard.
  TEST_ASSERT_EQUAL_UINT8(8, nthWeekdayOfMonth(2026, 3, 0, 2));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 3, 8, 1, 59));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 3, 8, 2, 0));
  // Ends the first Sunday in November 2026 = the 1st, at 02:00 daylight, which
  // is 01:00 standard. Getting this wrong by an hour is the classic US bug.
  TEST_ASSERT_EQUAL_UINT8(1, nthWeekdayOfMonth(2026, 11, 0, 1));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 11, 1, 0, 59));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 11, 1, 1, 0));
  // North America starts earlier and ends later than Europe, so there are
  // several weeks each year when the two are out of step.
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 3, 20, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(DstZone::EuropeCentral, 2026, 3, 20, 12, 0));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 10, 28, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(DstZone::EuropeCentral, 2026, 10, 28, 12, 0));
}

void test_north_america_across_several_years(void) {
  const DstZone z = DstZone::NorthAmerica;
  const uint16_t years[] = {2024, 2025, 2026, 2027, 2028, 2035};
  for (unsigned i = 0; i < sizeof(years) / sizeof(years[0]); i++) {
    const uint16_t y = years[i];
    const uint8_t mar = nthWeekdayOfMonth(y, 3, 0, 2);
    const uint8_t nov = nthWeekdayOfMonth(y, 11, 0, 1);
    TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(y, 3, mar));
    TEST_ASSERT_EQUAL_UINT8(0, weekdayOf(y, 11, nov));
    TEST_ASSERT_TRUE(mar >= 8 && mar <= 14);   // second Sunday, by definition
    TEST_ASSERT_TRUE(nov >= 1 && nov <= 7);    // first Sunday
    TEST_ASSERT_FALSE(isDstActive(z, y, 3, mar, 1, 59));
    TEST_ASSERT_TRUE(isDstActive(z, y, 3, mar, 2, 0));
    TEST_ASSERT_TRUE(isDstActive(z, y, 11, nov, 0, 59));
    TEST_ASSERT_FALSE(isDstActive(z, y, 11, nov, 1, 0));
    TEST_ASSERT_TRUE(isDstActive(z, y, 7, 4, 12, 0));    // summer
    TEST_ASSERT_FALSE(isDstActive(z, y, 12, 25, 12, 0));  // winter
  }
}

// ---- Southern hemisphere: the daylight period wraps the year end -----------

void test_chile_2026(void) {
  const DstZone z = DstZone::Chile;
  // January is summer in Chile, so daylight time is in force at the year start.
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 1, 1, 0, 0));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 1, 15, 12, 0));
  // Ends the first Sunday in April 2026 = the 5th, at 00:00 daylight, i.e.
  // 23:00 standard on Saturday the 4th. This is the case that would break a
  // rule engine that could not express a boundary before midnight.
  TEST_ASSERT_EQUAL_UINT8(5, nthWeekdayOfMonth(2026, 4, 0, 1));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 4, 4, 22, 59));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 4, 4, 23, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 4, 5, 0, 0));
  // Chilean winter.
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 7, 15, 12, 0));
  // Restarts the first Sunday in September 2026 = the 6th, at 00:00 standard.
  TEST_ASSERT_EQUAL_UINT8(6, nthWeekdayOfMonth(2026, 9, 0, 1));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 9, 5, 23, 59));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 9, 6, 0, 0));
  TEST_ASSERT_TRUE(isDstActive(z, 2026, 12, 25, 12, 0));
}

void test_australia_and_new_zealand_2026(void) {
  const DstZone au = DstZone::Australia;
  // Australian summer spans the new year.
  TEST_ASSERT_TRUE(isDstActive(au, 2026, 1, 15, 12, 0));
  // Ends first Sunday in April = the 5th, at 03:00 daylight = 02:00 standard.
  TEST_ASSERT_TRUE(isDstActive(au, 2026, 4, 5, 1, 59));
  TEST_ASSERT_FALSE(isDstActive(au, 2026, 4, 5, 2, 0));
  TEST_ASSERT_FALSE(isDstActive(au, 2026, 7, 15, 12, 0));
  // Starts first Sunday in October = the 4th, at 02:00 standard.
  TEST_ASSERT_EQUAL_UINT8(4, nthWeekdayOfMonth(2026, 10, 0, 1));
  TEST_ASSERT_FALSE(isDstActive(au, 2026, 10, 4, 1, 59));
  TEST_ASSERT_TRUE(isDstActive(au, 2026, 10, 4, 2, 0));

  const DstZone nz = DstZone::NewZealand;
  // New Zealand starts earlier than Australia: last Sunday in September = 27th.
  TEST_ASSERT_EQUAL_UINT8(27, nthWeekdayOfMonth(2026, 9, 0, -1));
  TEST_ASSERT_FALSE(isDstActive(nz, 2026, 9, 27, 1, 59));
  TEST_ASSERT_TRUE(isDstActive(nz, 2026, 9, 27, 2, 0));
  // So in early October the two are briefly out of step.
  TEST_ASSERT_TRUE(isDstActive(nz, 2026, 10, 1, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(au, 2026, 10, 1, 12, 0));
  // Both end on the same day.
  TEST_ASSERT_TRUE(isDstActive(nz, 2026, 4, 5, 1, 59));
  TEST_ASSERT_FALSE(isDstActive(nz, 2026, 4, 5, 2, 0));
}

// ---- Robustness ------------------------------------------------------------

void test_corrupt_input_never_shifts(void) {
  // A glitching I2C read must not be able to move the clock. July would
  // otherwise be daylight time for this zone.
  const DstZone z = DstZone::EuropeCentral;
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 0, 15, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 13, 15, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 7, 0, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 7, 32, 12, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 7, 15, 24, 0));
  TEST_ASSERT_FALSE(isDstActive(z, 2026, 7, 15, 12, 60));
  // An out-of-range zone (e.g. a corrupt NVS byte) must be inert, not index
  // past the rule table.
  TEST_ASSERT_FALSE(isDstActive(static_cast<DstZone>(200), 2026, 7, 15, 12, 0));
}

void test_zone_names_present(void) {
  // Every zone needs a non-empty label, or the settings screen shows a blank.
  for (uint8_t i = 0; i < static_cast<uint8_t>(DstZone::Count); i++) {
    const char* name = dstZoneName(static_cast<DstZone>(i));
    TEST_ASSERT_NOT_NULL(name);
    TEST_ASSERT_TRUE(name[0] != '\0');
  }
  // Out-of-range is safe.
  TEST_ASSERT_NOT_NULL(dstZoneName(static_cast<DstZone>(200)));
}

void test_every_zone_has_two_transitions_a_year(void) {
  // Walk every hour of 2026 for every zone and count the flips. Any rule that
  // never engages, never disengages, or oscillates would show up here.
  for (uint8_t i = 1; i < static_cast<uint8_t>(DstZone::Count); i++) {
    const DstZone z = static_cast<DstZone>(i);
    int flips = 0;
    bool prev = isDstActive(z, 2026, 1, 1, 0, 0);
    const bool atYearStart = prev;
    for (uint8_t m = 1; m <= 12; m++) {
      for (uint8_t d = 1; d <= daysInMonth(2026, m); d++) {
        for (uint8_t h = 0; h < 24; h++) {
          bool cur = isDstActive(z, 2026, m, d, h, 0);
          if (cur != prev) flips++;
          prev = cur;
        }
      }
    }
    TEST_ASSERT_EQUAL_INT(2, flips);
    // And the year must end as it began - the daylight period is annual.
    TEST_ASSERT_EQUAL_INT(atYearStart ? 1 : 0, prev ? 1 : 0);
  }
}

int main(int, char**) {
  UNITY_BEGIN();
  RUN_TEST(test_days_in_month_leap_years);
  RUN_TEST(test_days_from_civil_epoch);
  RUN_TEST(test_weekday_known_dates);
  RUN_TEST(test_nth_weekday_of_month);
  RUN_TEST(test_off_never_shifts);
  RUN_TEST(test_europe_west_2026);
  RUN_TEST(test_europe_central_2026);
  RUN_TEST(test_europe_east_2026);
  RUN_TEST(test_europe_across_several_years);
  RUN_TEST(test_north_america_2026);
  RUN_TEST(test_north_america_across_several_years);
  RUN_TEST(test_chile_2026);
  RUN_TEST(test_australia_and_new_zealand_2026);
  RUN_TEST(test_corrupt_input_never_shifts);
  RUN_TEST(test_zone_names_present);
  RUN_TEST(test_every_zone_has_two_transitions_a_year);
  return UNITY_END();
}
