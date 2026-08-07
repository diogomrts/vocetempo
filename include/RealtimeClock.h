/*
 * RealtimeClock - thin wrapper around the DS3231 RTC (I2C).
 *
 * Hides RTClib behind a small project API so the rest of the code deals in
 * simple values (hours, minutes, formatted strings) rather than library
 * types. Shares the I2C bus with the display (addresses: RTC 0x68).
 *
 * Daylight saving
 * ---------------
 * The DS3231 hardware always holds LOCAL STANDARD TIME (winter time); it is
 * never rewritten for a DST transition, so the hardware keeps ticking
 * undisturbed. This class is the single place where the daylight offset is
 * applied: every read (now(), timeString(), dateString()) returns local time
 * with the offset added, and every write (setDateTime()) takes local time and
 * removes it again. So callers - and the user - only ever see wall time, and
 * nothing else in the firmware needs to know DST exists.
 *
 * With no zone set (the default) the offset is always zero and behaviour is
 * identical to a plain wall clock. See Dst.h for the rules.
 */

#ifndef VOCETEMPO_REALTIMECLOCK_H
#define VOCETEMPO_REALTIMECLOCK_H

#include <Arduino.h>

#include "Dst.h"

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

  // Select the daylight-saving region. Call once at boot from settings, and
  // again whenever the user changes it. DstZone::Off disables DST entirely.
  //
  // This only changes how the stored value is *interpreted*; it does not touch
  // the RTC. So switching to a region that is currently on summer time makes
  // the same stored reading come back an hour later. Callers that change the
  // zone on a clock the user has already set should therefore re-write the wall
  // time afterwards to keep it stable - see Menu::handleEditDst(), which does
  // exactly that so the displayed time never moves when a region is chosen.
  void setDstZone(DstZone zone) { _dstZone = zone; }
  DstZone dstZone() const { return _dstZone; }

  // True if daylight saving is currently in effect (i.e. reads are being
  // shifted forward an hour). False when no zone is set or the RTC is absent.
  bool dstActive();

  // Set the RTC to a specific LOCAL date/time - the time as the user reads it
  // off the wall, daylight offset included. The offset is removed before the
  // value is stored, so what is written to hardware is standard time.
  void setDateTime(uint16_t year, uint8_t month, uint8_t day,
                   uint8_t hour, uint8_t minute, uint8_t second);

  // Set the RTC from the host's compile time (handy for a first rough set).
  // Treated as local time, so the same DST reversal applies.
  void setToCompileTime();

  // Read the current LOCAL time components (daylight offset already applied).
  // Returns false if the RTC isn't ready or the read looked corrupt. `weekday`
  // is the weekday of the local date, which matters because the offset can
  // push the local time over midnight into the next day.
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
  DstZone _dstZone = DstZone::Off;
};

#endif  // VOCETEMPO_REALTIMECLOCK_H
