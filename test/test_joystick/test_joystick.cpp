/*
 * Host unit tests for the KY-023 axis decoder in src/Joystick.cpp.
 *
 *   pio test -e native
 *
 * Everything here is about the three failure modes that are miserable to debug
 * on real hardware: a stick that chatters near the deadzone edge, a diagonal
 * push that fires two actions at once, and an axis that reads backwards.
 */

#include <unity.h>

#include "Joystick.h"

static const uint16_t C = Joystick::kAdcCentreNominal;  // 2048

// A deflection comfortably past the engage threshold, and one comfortably
// inside the release threshold, so tests read as intent rather than arithmetic.
static const int32_t kPush = Joystick::kEngage + 200;
static const int32_t kIdle = Joystick::kRelease - 200;

static uint16_t at(int32_t deltaFromCentre) {
  int32_t v = static_cast<int32_t>(C) + deltaFromCentre;
  if (v < 0) v = 0;
  if (v > Joystick::kAdcMax) v = Joystick::kAdcMax;
  return static_cast<uint16_t>(v);
}

// ---- Resting behaviour ------------------------------------------------------

void test_centred_stick_reports_nothing(void) {
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, C));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.direction());
}

void test_adc_jitter_around_centre_is_ignored(void) {
  // Real ADC readings wander by tens of counts. None of that may produce input.
  Joystick j;
  const int32_t jitter[] = {0, 7, -9, 23, -31, 44, -52, 18, -3};
  for (unsigned i = 0; i < sizeof(jitter) / sizeof(jitter[0]); i++) {
    for (unsigned k = 0; k < sizeof(jitter) / sizeof(jitter[0]); k++) {
      TEST_ASSERT_EQUAL_INT((int)JoyDir::None,
                            (int)j.update(at(jitter[i]), at(jitter[k])));
    }
  }
}

void test_deflection_below_engage_does_nothing(void) {
  Joystick j;
  // Just short of the threshold on each axis in turn.
  const int32_t justUnder = Joystick::kEngage - 1;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, at(-justUnder)));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, at(justUnder)));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(at(-justUnder), C));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(at(justUnder), C));
  // And exactly at the threshold it engages, so the boundary is not off by one.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up,
                        (int)j.update(C, at(-(int32_t)Joystick::kEngage)));
}

// ---- The four directions ---------------------------------------------------

void test_four_directions(void) {
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-kPush)));
  j.update(C, C);  // release between pushes
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down, (int)j.update(C, at(kPush)));
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Left, (int)j.update(at(-kPush), C));
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Right, (int)j.update(at(kPush), C));
}

void test_invert_flips_axes(void) {
  Joystick j;
  j.setInvert(true, true);
  // With both axes inverted, the same raw readings mean the opposite direction.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down, (int)j.update(C, at(-kPush)));
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Right, (int)j.update(at(-kPush), C));

  // Inverting only one axis leaves the other alone.
  Joystick k;
  k.setInvert(false, true);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down, (int)k.update(C, at(-kPush)));
  k.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Left, (int)k.update(at(-kPush), C));
}

void test_calibrated_centre_shifts_the_deadzone(void) {
  // A stick that rests off-centre must still read as idle at rest, and must
  // still need a full push from THERE to engage.
  Joystick j;
  const uint16_t restX = 1750, restY = 2300;
  j.setCentre(restX, restY);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(restX, restY));
  TEST_ASSERT_EQUAL_UINT16(restX, j.centreX());
  TEST_ASSERT_EQUAL_UINT16(restY, j.centreY());

  // The nominal midpoint is now a real deflection on Y (2048 - 2300 = -252),
  // but still well under the engage threshold, so it stays idle.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, C));

  // A push measured from the true resting point engages as normal.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(restX, restY - kPush));
}

// ---- Hysteresis ------------------------------------------------------------

void test_hysteresis_holds_between_thresholds(void) {
  Joystick j;
  // Engage with a firm push.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-kPush)));

  // Easing back into the gap between release and engage must NOT let go. This
  // is what stops a stick resting near the threshold from chattering.
  const int32_t between = (Joystick::kEngage + Joystick::kRelease) / 2;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-between)));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-between)));

  // Only once it falls below the release threshold does it let go.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, at(-kIdle)));
}

void test_no_chatter_when_resting_at_the_engage_edge(void) {
  // The regression this whole design exists for: a stick sitting right at the
  // engage point with noise on top must not produce a stream of events.
  Joystick j;
  int engagements = 0;
  JoyDir prev = JoyDir::None;
  const int32_t noise[] = {0, 12, -15, 8, -20, 17, -6, 25, -11};
  for (int pass = 0; pass < 20; pass++) {
    const int32_t n = noise[pass % (sizeof(noise) / sizeof(noise[0]))];
    JoyDir d = j.update(C, at(-((int32_t)Joystick::kEngage - 40 + n)));
    if (d != JoyDir::None && prev == JoyDir::None) engagements++;
    prev = d;
  }
  // Hovering just below engage with noise crossing it may legitimately engage
  // once, but hysteresis must stop it toggling over and over.
  TEST_ASSERT_TRUE(engagements <= 1);
}

// ---- Dominant axis: the diagonal problem -----------------------------------

void test_dominant_axis_wins_a_diagonal_push(void) {
  // Pushing up-and-right must be "up" only, never up plus a confirm.
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up,
                        (int)j.update(at(kPush / 2), at(-kPush)));
  j.update(C, C);
  // And the other way round: mostly right with some up.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Right,
                        (int)j.update(at(kPush), at(-kPush / 2)));
}

void test_ties_favour_the_vertical_axis(void) {
  // Exactly diagonal is ambiguous; menu scrolling is the safer default than an
  // accidental confirm or a menu exit.
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(at(kPush), at(-kPush)));
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down, (int)j.update(at(-kPush), at(kPush)));
}

void test_engaged_axis_locks_out_the_other(void) {
  // Hold up, then push hard sideways WITHOUT releasing. The sideways push must
  // be ignored - otherwise scrolling a menu with a sloppy thumb would fire OK.
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-kPush)));
  for (int i = 0; i < 10; i++) {
    TEST_ASSERT_EQUAL_INT((int)JoyDir::Up,
                          (int)j.update(at(kPush * 2), at(-kPush)));
  }
  // Release, and only then can the other axis take over.
  TEST_ASSERT_EQUAL_INT((int)JoyDir::None, (int)j.update(C, C));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Right, (int)j.update(at(kPush), C));
}

void test_sliding_across_one_axis_without_releasing(void) {
  // Sweeping from up to down in one motion should end up reporting Down, not
  // staying stuck on Up.
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, at(-kPush)));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down, (int)j.update(C, at(kPush)));
  // Same on the horizontal axis.
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Left, (int)j.update(at(-kPush), C));
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Right, (int)j.update(at(kPush), C));
}

// ---- Calibration guard -----------------------------------------------------

void test_centre_plausibility(void) {
  // A genuinely centred stick, including realistic ADC non-linearity.
  TEST_ASSERT_TRUE(Joystick::centreIsPlausible(2048, 2048));
  TEST_ASSERT_TRUE(Joystick::centreIsPlausible(1900, 2100));
  TEST_ASSERT_TRUE(Joystick::centreIsPlausible(1500, 2500));

  // A stick held at boot must be rejected, or the bad offset would be baked in
  // for the whole session and could leave a direction stuck on.
  TEST_ASSERT_FALSE(Joystick::centreIsPlausible(2048, 100));
  TEST_ASSERT_FALSE(Joystick::centreIsPlausible(4095, 2048));
  // A disconnected axis reads a rail, which must be rejected too.
  TEST_ASSERT_FALSE(Joystick::centreIsPlausible(0, 0));
  TEST_ASSERT_FALSE(Joystick::centreIsPlausible(4095, 4095));
}

void test_rail_readings_engage_rather_than_hang(void) {
  // If an axis is pinned to a rail the stick reads as fully deflected. That
  // should behave like a firm push, not produce None or a wrong axis.
  Joystick j;
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Up, (int)j.update(C, 0));
  j.update(C, C);
  TEST_ASSERT_EQUAL_INT((int)JoyDir::Down,
                        (int)j.update(C, Joystick::kAdcMax));
}

int main(int, char**) {
  UNITY_BEGIN();
  RUN_TEST(test_centred_stick_reports_nothing);
  RUN_TEST(test_adc_jitter_around_centre_is_ignored);
  RUN_TEST(test_deflection_below_engage_does_nothing);
  RUN_TEST(test_four_directions);
  RUN_TEST(test_invert_flips_axes);
  RUN_TEST(test_calibrated_centre_shifts_the_deadzone);
  RUN_TEST(test_hysteresis_holds_between_thresholds);
  RUN_TEST(test_no_chatter_when_resting_at_the_engage_edge);
  RUN_TEST(test_dominant_axis_wins_a_diagonal_push);
  RUN_TEST(test_ties_favour_the_vertical_axis);
  RUN_TEST(test_engaged_axis_locks_out_the_other);
  RUN_TEST(test_sliding_across_one_axis_without_releasing);
  RUN_TEST(test_centre_plausibility);
  RUN_TEST(test_rail_readings_engage_rather_than_hang);
  return UNITY_END();
}
