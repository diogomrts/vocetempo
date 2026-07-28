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
  String weekdayString();                           // "Tuesday"

 private:
  bool _ready = false;
};

#endif  // VOCETEMPO_REALTIMECLOCK_H
