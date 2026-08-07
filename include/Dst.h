/*
 * Dst - daylight saving time rules.
 *
 * Vocetempo is deliberately offline, so it cannot download a timezone
 * database. It does not need one: every jurisdiction below switches on an
 * algorithmic rule ("last Sunday in March", "second Sunday in March"), so the
 * transitions can be computed on-device, correctly, forever.
 *
 * -------------------------------------------------------------------------
 * How time is represented
 * -------------------------------------------------------------------------
 * The DS3231 always stores LOCAL STANDARD TIME (winter time). It is never
 * touched by a DST transition, so the hardware clock keeps ticking undisturbed
 * twice a year. RealtimeClock adds the daylight offset when it *reads* the RTC
 * and removes it again when it *writes*, so the rest of the firmware - and the
 * user - only ever deal with the time as it appears on the wall.
 *
 * Zone is Off by default: with no zone selected nothing is shifted and the
 * clock behaves exactly as a plain wall clock, as before.
 *
 * -------------------------------------------------------------------------
 * How a rule is expressed
 * -------------------------------------------------------------------------
 * Start boundaries are given in local STANDARD time and end boundaries in
 * local DAYLIGHT time, because that is the convention every legislature uses
 * ("clocks go back at 2am"). Both are converted to a single linear
 * minutes-since-1970 scale before comparing, which makes the arithmetic
 * uniform and handles the awkward cases for free:
 *
 *   - An end boundary that lands before midnight in standard time (Chile ends
 *     at 00:00 daylight = 23:00 standard the previous day).
 *   - Southern-hemisphere zones, where the daylight period wraps the year end.
 *
 * This file has no Arduino or RTClib dependency on purpose, so the rules are
 * unit-testable on the host (see test/test_dst/).
 */

#ifndef VOCETEMPO_DST_H
#define VOCETEMPO_DST_H

#include <stdint.h>

// Selectable DST region. Off means "no daylight saving" - the default, and
// correct for most of Asia and Africa, and for Brazil, Argentina, Russia,
// India, China, Japan, Mexico (interior) and Turkey, none of which observe DST
// any more.
//
// The enum values are persisted in NVS, so only ever append to this list;
// never renumber it.
enum class DstZone : uint8_t {
  Off = 0,
  EuropeWest,     // UK, Ireland, Portugal, Canary Islands   (UTC+0)
  EuropeCentral,  // Spain, France, Germany, Italy, Poland   (UTC+1)
  EuropeEast,     // Greece, Finland, Romania, Baltics       (UTC+2)
  NorthAmerica,   // USA, Canada, Mexican border zone
  Chile,          // southern hemisphere
  Australia,      // NSW, Victoria, South Australia, Tasmania, ACT
  NewZealand,     // southern hemisphere
  Count
};

// Short place name for a zone, for the settings screen. These are proper
// nouns, so they are intentionally not translated. Off returns "Off"; the menu
// substitutes the localized word instead.
const char* dstZoneName(DstZone zone);

// True if daylight saving is in effect for `zone` at the given LOCAL STANDARD
// date/time. Always false for DstZone::Off.
bool isDstActive(DstZone zone, uint16_t year, uint8_t month, uint8_t day,
                 uint8_t hour, uint8_t minute);

// Minutes to add to local standard time to get local time: 0 outside the
// daylight period, otherwise the zone's offset (60 for every zone here).
uint8_t dstOffsetMinutes(DstZone zone, uint16_t year, uint8_t month,
                         uint8_t day, uint8_t hour, uint8_t minute);

// ---- Calendar helpers (exposed so they can be tested, and reused by Menu) ----

// Number of days in a month, honouring the full Gregorian leap-year rule.
// Returns 31 for an out-of-range month so callers can never index past a
// buffer or clamp a day to 0.
uint8_t daysInMonth(uint16_t year, uint8_t month);

// Days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant's
// days_from_civil). Negative for dates before 1970.
int32_t daysFromCivil(uint16_t year, uint8_t month, uint8_t day);

// Day of the week for a date, 0=Sunday .. 6=Saturday (matches RTClib's
// DateTime::dayOfTheWeek() and Localization's weekdayName()).
uint8_t weekdayOf(uint16_t year, uint8_t month, uint8_t day);

// Day-of-month of the nth given weekday in a month. `nth` is 1..5 for "first"
// .. "fifth", or -1 for "last". Returns 0 if that occurrence does not exist
// (e.g. a fifth Sunday in a month that has only four).
uint8_t nthWeekdayOfMonth(uint16_t year, uint8_t month, uint8_t weekday,
                          int8_t nth);

#endif  // VOCETEMPO_DST_H
