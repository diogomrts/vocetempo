/*
 * Joystick - decodes a KY-023 analog thumbstick into a single direction.
 *
 * The KY-023 is two potentiometers (one per axis) plus a push-down switch. Each
 * axis reads roughly mid-scale at rest and swings toward 0 or full-scale as the
 * stick is pushed. This class turns those two noisy numbers into one clean
 * answer: which way is the stick being pushed right now, if any.
 *
 * Three things make that reliable, and all three are the reason this is a class
 * rather than a pair of if-statements:
 *
 *   1. Deadzone. The stick never returns exactly to centre and the ESP32 ADC
 *      jitters by tens of counts, so a deflection must exceed kEngage before it
 *      counts as intentional.
 *
 *   2. Hysteresis. Releasing uses a lower threshold (kRelease) than engaging.
 *      Without the gap, a stick resting near the engage point would chatter on
 *      and off every few milliseconds and the UI would run away.
 *
 *   3. Dominant-axis latch. A thumbstick is physically impossible to push
 *      exactly along one axis, so a push "up" always carries some sideways
 *      deflection. Only the axis with the larger deflection wins, and once a
 *      direction is engaged the other axis is ignored entirely until the stick
 *      is released. Without this, nudging up-and-right in a menu would scroll
 *      AND confirm in the same gesture.
 *
 * This file deliberately has no Arduino dependency - it takes raw numbers, not
 * pins - so all of the above is unit-tested on the host. See test/test_joystick/.
 * The ADC reads and the switch live in Buttons.cpp, which owns an instance of
 * this class and maps its output onto the four logical UI actions.
 */

#ifndef VOCETEMPO_JOYSTICK_H
#define VOCETEMPO_JOYSTICK_H

#include <stdint.h>

// Which way the stick is currently being pushed. Exactly one at a time, by
// design (see the dominant-axis latch above).
enum class JoyDir : uint8_t { None, Up, Down, Left, Right };

class Joystick {
 public:
  // The ESP32 ADC is 12-bit by default, so an axis reads 0..4095 and sits near
  // half scale at rest.
  static const uint16_t kAdcMax = 4095;
  static const uint16_t kAdcCentreNominal = 2048;

  // Deflection needed to engage a direction, and the lower value it must fall
  // back below to release it. Roughly 20% and 11% of full scale: far above ADC
  // noise, but still a light push. Tune with tools/joystick_test if the stick
  // feels too eager or too stiff.
  static const uint16_t kEngage = 800;
  static const uint16_t kRelease = 450;

  // How far a resting reading may sit from kAdcCentreNominal and still be
  // trusted as a calibration sample. Real ESP32 ADCs are non-linear and read
  // centre anywhere around 1900-2100, so the window is generous; it exists only
  // to reject a stick that was being held at boot.
  static const uint16_t kCentreTolerance = 700;

  // Store the measured resting position of each axis. Readings are compared
  // against this, not against a hard-coded midpoint, so unit-to-unit variation
  // in the potentiometers does not bias the deadzone.
  void setCentre(uint16_t centreX, uint16_t centreY);
  uint16_t centreX() const { return _centreX; }
  uint16_t centreY() const { return _centreY; }

  // Flip an axis if the module is mounted rotated or its pots run the opposite
  // way. Determine empirically with tools/joystick_test after assembly.
  void setInvert(bool invertX, bool invertY);

  // Feed one raw sample of each axis (0..kAdcMax). Returns the direction now
  // engaged, which is also what direction() reports until the next call.
  JoyDir update(uint16_t rawX, uint16_t rawY);

  JoyDir direction() const { return _active; }

  // True if a resting sample looks like a genuinely centred stick, so it is
  // safe to calibrate from. False if the stick was held (or an axis is
  // disconnected and reading a rail), in which case the caller should keep the
  // nominal centre instead of baking a bad offset in for the whole session.
  static bool centreIsPlausible(uint16_t rawX, uint16_t rawY);

 private:
  uint16_t _centreX = kAdcCentreNominal;
  uint16_t _centreY = kAdcCentreNominal;
  bool _invertX = false;
  bool _invertY = false;
  JoyDir _active = JoyDir::None;
};

#endif  // VOCETEMPO_JOYSTICK_H
