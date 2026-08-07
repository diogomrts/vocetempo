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
 *
 * Only <stdint.h> is needed here (no Arduino types), which keeps the class
 * host-compilable so its logic can be unit-tested - see test/test_announcer/.
 */

#ifndef VOCETEMPO_ANNOUNCER_H
#define VOCETEMPO_ANNOUNCER_H

#include <stdint.h>

enum class AnnounceInterval : uint8_t { Off, Hourly, Half, Quarter,
                                        TestEveryMinute };

class Announcer {
 public:
  void setInterval(AnnounceInterval interval) { _interval = interval; }
  AnnounceInterval interval() const { return _interval; }

  // Quiet hours: automatic announcements are suppressed when the current time
  // is within [startHour:startMin, endHour:endMin). Handles overnight windows
  // that wrap past midnight (e.g. 22:00 -> 08:00). Set enabled=false to
  // disable quiet hours entirely.
  void setQuietHours(bool enabled, uint8_t startHour, uint8_t startMin,
                     uint8_t endHour, uint8_t endMin);

  // True if the given time falls inside the active quiet-hours window.
  bool isQuietNow(uint8_t hour, uint8_t minute) const;

  // Call every loop with the current hour/minute/second. Returns true exactly
  // once when an automatic announcement should happen for this time slot.
  // Automatically returns false during quiet hours.
  bool shouldAnnounce(uint8_t hour, uint8_t minute, uint8_t second);

 private:
  AnnounceInterval _interval = AnnounceInterval::Off;

  bool _quietEnabled = false;
  uint16_t _quietStart = 0;  // minutes since midnight
  uint16_t _quietEnd = 0;

  // Guard so a boundary fires once, not on every one of the ~200 loop
  // iterations that fall inside its zero-second window.
  //
  // It latches on firing and is released as soon as the clock reads a
  // different minute. Deliberately NOT "have I already announced this
  // (hour, minute) value?": on a daylight-saving fall-back the clock legitimately
  // repeats an hour, and a value-based guard would suppress every boundary in
  // the replayed hour, silencing the clock. Releasing on change means the
  // repeated hour is announced again, which is the correct behaviour.
  bool _fired = false;
  uint8_t _firedHour = 0;
  uint8_t _firedMinute = 0;

  bool isBoundaryMinute(uint8_t minute) const;
};

#endif  // VOCETEMPO_ANNOUNCER_H
