/*
 * Announcer - decides WHEN the clock should speak the time automatically.
 *
 * Watches the current time and fires on the configured interval boundaries.
 * The actual speaking is done by the caller (using Audio), so this class has
 * no hardware dependencies and is easy to test/reason about.
 *
 * Intervals:
 *   Off      - never auto-announce
 *   Hourly   - at minute 00
 *   Half     - at minute 00 and 30
 *   Quarter  - at minute 00, 15, 30, 45
 */

#ifndef VOCETEMPO_ANNOUNCER_H
#define VOCETEMPO_ANNOUNCER_H

#include <Arduino.h>

enum class AnnounceInterval : uint8_t { Off, Hourly, Half, Quarter,
                                        TestEveryMinute };

class Announcer {
 public:
  void setInterval(AnnounceInterval interval) { _interval = interval; }
  AnnounceInterval interval() const { return _interval; }

  // Call every loop with the current hour/minute/second. Returns true exactly
  // once when an automatic announcement should happen for this time slot.
  bool shouldAnnounce(uint8_t hour, uint8_t minute, uint8_t second);

 private:
  AnnounceInterval _interval = AnnounceInterval::Off;

  // Remember the last minute we announced so we only fire once per boundary.
  int _lastAnnouncedMinute = -1;
  int _lastAnnouncedHour = -1;

  bool isBoundaryMinute(uint8_t minute) const;
};

#endif  // VOCETEMPO_ANNOUNCER_H
