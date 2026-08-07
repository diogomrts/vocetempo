/*
 * Host unit tests for the announcement scheduler in src/Announcer.cpp.
 *
 *   pio test -e native
 *
 * The main loop calls shouldAnnounce() every few milliseconds, so these tests
 * feed it the same way - many calls per second - rather than once per minute.
 * That is the only way to exercise the once-per-boundary guard honestly.
 */

#include <unity.h>

#include "Announcer.h"

// Loop rate in main.cpp is roughly one iteration per 5ms; 40 calls per second
// is plenty to prove the guard holds without making the tests slow.
static const int kCallsPerSecond = 40;

// Feed one whole second of loop iterations and return how many times the
// announcer said "speak now". Anything other than 0 or 1 is a bug.
static int firesDuringSecond(Announcer& a, uint8_t h, uint8_t m, uint8_t s) {
  int fires = 0;
  for (int i = 0; i < kCallsPerSecond; i++) {
    if (a.shouldAnnounce(h, m, s)) fires++;
  }
  return fires;
}

// Feed a whole minute (all 60 seconds) and return the total number of fires.
static int firesDuringMinute(Announcer& a, uint8_t h, uint8_t m) {
  int fires = 0;
  for (uint8_t s = 0; s < 60; s++) fires += firesDuringSecond(a, h, m, s);
  return fires;
}

// ---- Interval boundaries ---------------------------------------------------

void test_off_never_announces(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Off);
  for (uint8_t h = 0; h < 24; h++) {
    TEST_ASSERT_EQUAL_INT(0, firesDuringMinute(a, h, 0));
  }
}

void test_hourly_fires_once_per_hour(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  int total = 0;
  for (uint8_t h = 0; h < 24; h++) {
    for (uint8_t m = 0; m < 60; m++) {
      int fires = firesDuringMinute(a, h, m);
      // Exactly one announcement, at minute 0, no matter how many times the
      // loop asked during that minute.
      TEST_ASSERT_EQUAL_INT(m == 0 ? 1 : 0, fires);
      total += fires;
    }
  }
  TEST_ASSERT_EQUAL_INT(24, total);
}

void test_quarter_fires_four_times_per_hour(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Quarter);
  int total = 0;
  for (uint8_t m = 0; m < 60; m++) {
    int fires = firesDuringMinute(a, 9, m);
    TEST_ASSERT_EQUAL_INT((m % 15 == 0) ? 1 : 0, fires);
    total += fires;
  }
  TEST_ASSERT_EQUAL_INT(4, total);
}

void test_half_fires_twice_per_hour(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Half);
  int total = 0;
  for (uint8_t m = 0; m < 60; m++) total += firesDuringMinute(a, 9, m);
  TEST_ASSERT_EQUAL_INT(2, total);
}

void test_never_fires_off_the_zero_second(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  // Join the minute late (as happens after a blocking announcement or an I2C
  // retry): no second-0 sample, so no announcement for that boundary.
  for (uint8_t s = 1; s < 60; s++) {
    TEST_ASSERT_EQUAL_INT(0, firesDuringSecond(a, 10, 0, s));
  }
}

// ---- Quiet hours -----------------------------------------------------------

void test_quiet_hours_same_day_window(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  a.setQuietHours(true, 1, 0, 6, 0);  // 01:00 -> 06:00

  TEST_ASSERT_FALSE(a.isQuietNow(0, 59));
  TEST_ASSERT_TRUE(a.isQuietNow(1, 0));
  TEST_ASSERT_TRUE(a.isQuietNow(5, 59));
  TEST_ASSERT_FALSE(a.isQuietNow(6, 0));  // end is exclusive

  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 0, 0));
  TEST_ASSERT_EQUAL_INT(0, firesDuringMinute(a, 2, 0));
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 6, 0));
}

void test_quiet_hours_overnight_window(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  a.setQuietHours(true, 22, 0, 8, 0);  // the default 22:00 -> 08:00

  TEST_ASSERT_TRUE(a.isQuietNow(23, 0));
  TEST_ASSERT_TRUE(a.isQuietNow(0, 0));
  TEST_ASSERT_TRUE(a.isQuietNow(7, 59));
  TEST_ASSERT_FALSE(a.isQuietNow(8, 0));
  TEST_ASSERT_FALSE(a.isQuietNow(21, 59));
  TEST_ASSERT_TRUE(a.isQuietNow(22, 0));

  // Only the waking hours announce.
  int total = 0;
  for (uint8_t h = 0; h < 24; h++) total += firesDuringMinute(a, h, 0);
  TEST_ASSERT_EQUAL_INT(14, total);  // 08:00..21:00 inclusive
}

void test_quiet_hours_zero_length_and_disabled(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  // Equal start and end means "never quiet", not "always quiet".
  a.setQuietHours(true, 9, 0, 9, 0);
  TEST_ASSERT_FALSE(a.isQuietNow(9, 0));
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 9, 0));

  a.setQuietHours(false, 22, 0, 8, 0);
  TEST_ASSERT_FALSE(a.isQuietNow(2, 0));
}

// ---- Daylight-saving transitions -------------------------------------------

void test_dst_fall_back_repeated_hour_still_announces(void) {
  // The regression test for the reason this guard was rewritten.
  //
  // On a fall-back night the local clock runs ...01:58, 01:59, then jumps back
  // to 01:00 and repeats the whole hour. A guard that remembered "I have
  // already announced 01:00" would suppress every boundary in the replayed
  // hour and the clock would go silent for an hour.
  Announcer a;
  a.setInterval(AnnounceInterval::Quarter);
  a.setQuietHours(false, 0, 0, 0, 0);

  int firstPass = 0;
  for (uint8_t m = 0; m < 60; m++) firstPass += firesDuringMinute(a, 1, m);
  TEST_ASSERT_EQUAL_INT(4, firstPass);

  // Clocks go back: the same hour is lived again.
  int secondPass = 0;
  for (uint8_t m = 0; m < 60; m++) secondPass += firesDuringMinute(a, 1, m);
  TEST_ASSERT_EQUAL_INT(4, secondPass);

  // And the hour after the repeat behaves normally.
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 2, 0));
}

void test_dst_fall_back_hourly(void) {
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);

  // 01:00 announced, the rest of the hour passes, 01:00 comes round again.
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 1, 0));
  TEST_ASSERT_EQUAL_INT(0, firesDuringMinute(a, 1, 30));
  TEST_ASSERT_EQUAL_INT(0, firesDuringMinute(a, 1, 59));
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 1, 0));  // repeated hour
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 2, 0));
}

void test_dst_spring_forward_skips_missing_hour(void) {
  // Going forward, local time jumps 01:59 -> 03:00. The 02:00 boundary never
  // exists, so it is simply not announced - and 03:00 must not be swallowed.
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);

  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 1, 0));
  TEST_ASSERT_EQUAL_INT(0, firesDuringMinute(a, 1, 59));
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 3, 0));
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 4, 0));
}

void test_guard_survives_a_stalled_clock(void) {
  // If the RTC read fails the main loop stops calling us; when it resumes the
  // clock may still be inside the same boundary minute. It must not re-announce
  // a time it has already spoken.
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  TEST_ASSERT_EQUAL_INT(1, firesDuringSecond(a, 10, 0, 0));
  TEST_ASSERT_EQUAL_INT(0, firesDuringSecond(a, 10, 0, 0));
  TEST_ASSERT_EQUAL_INT(0, firesDuringSecond(a, 10, 0, 0));
}

void test_guard_clears_while_interval_off(void) {
  // Turning announcements off and on again must not leave a stale latch that
  // eats the next boundary. The same path covers being muted, since main.cpp
  // keeps calling shouldAnnounce() either way.
  Announcer a;
  a.setInterval(AnnounceInterval::Hourly);
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 10, 0));

  a.setInterval(AnnounceInterval::Off);
  for (uint8_t m = 1; m < 60; m++) firesDuringMinute(a, 10, m);

  // A day later, at the very same time of day, it announces again.
  a.setInterval(AnnounceInterval::Hourly);
  TEST_ASSERT_EQUAL_INT(1, firesDuringMinute(a, 10, 0));
}

int main(int, char**) {
  UNITY_BEGIN();
  RUN_TEST(test_off_never_announces);
  RUN_TEST(test_hourly_fires_once_per_hour);
  RUN_TEST(test_quarter_fires_four_times_per_hour);
  RUN_TEST(test_half_fires_twice_per_hour);
  RUN_TEST(test_never_fires_off_the_zero_second);
  RUN_TEST(test_quiet_hours_same_day_window);
  RUN_TEST(test_quiet_hours_overnight_window);
  RUN_TEST(test_quiet_hours_zero_length_and_disabled);
  RUN_TEST(test_dst_fall_back_repeated_hour_still_announces);
  RUN_TEST(test_dst_fall_back_hourly);
  RUN_TEST(test_dst_spring_forward_skips_missing_hour);
  RUN_TEST(test_guard_survives_a_stalled_clock);
  RUN_TEST(test_guard_clears_while_interval_off);
  return UNITY_END();
}
