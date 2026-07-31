/*
 * RealtimeClock - thin wrapper around the DS3231 RTC (I2C).
 *
 * Hides RTClib behind a small project API so the rest of the code deals in
 * simple values (hours, minutes, formatted strings) rather than library
 * types. Shares the I2C bus with the display (addresses: RTC 0x68).
 */

#ifndef VOCETEMPO_REALTIMECLOCK_H
#define VOCETEMPO_REALTIMECLOCK_H

#include <Arduino.h>

class RealtimeClock {
 public:
  // Initialise the DS3231 over I2C. Returns false if the RTC is not found.
  // Assumes Wire.begin() has already been called (the Display does this).
  bool begin();

  // True if the RTC reports it lost power since it was last set. Useful to
  // know whether the stored time is trustworthy (relevant once we add a
  // backup battery / supercap).
  bool lostPower();

  // Debounced version of lostPower() used at boot before we ever auto-write
  // the RTC. Reads the flag several times and only returns true if every read
  // agrees. A glitching I2C bus can return a garbage "power lost" flag; this
  // ensures such a glitch can NEVER trigger a spurious overwrite of a clock
  // that is actually keeping good time. Explicit menu sets remain the only
  // unconditional write path.
  bool powerReallyLost();

  // Set the RTC to a specific date/time.
  void setDateTime(uint16_t year, uint8_t month, uint8_t day,
                   uint8_t hour, uint8_t minute, uint8_t second);

  // Set the RTC from the host's compile time (handy for a first rough set).
  void setToCompileTime();

  // Read the current time components. Returns false if the RTC isn't ready.
  bool now(uint16_t& year, uint8_t& month, uint8_t& day,
           uint8_t& hour, uint8_t& minute, uint8_t& second,
           uint8_t& weekday);

  // Convenience formatters for the UI.
  String timeString(bool includeSeconds = false);  // "14:07" or "14:07:32"
  String dateString();                              // "2026-07-28"
  // (Weekday names are localized via weekdayName() in Localization.h, called
  // with the raw day-of-week, so there is no weekdayString() here.)

 private:
  bool _ready = false;
};

#endif  // VOCETEMPO_REALTIMECLOCK_H
