#include "RealtimeClock.h"

#include <RTClib.h>

// The RTClib driver instance, kept file-local.
static RTC_DS3231 rtc;

// Range-check a raw RTC read. A glitching I2C bus can return garbage; rejecting
// it here means nonsense never reaches the UI, an announcement, or the DST
// rules. RTClib's isValid() checks the fields parse; we bound-check too.
static bool plausible(const DateTime& t) {
  return t.isValid() && t.hour() <= 23 && t.minute() <= 59 &&
         t.second() <= 59 && t.month() >= 1 && t.month() <= 12 &&
         t.day() >= 1 && t.day() <= 31;
}

// Convert a standard-time reading from the hardware into local time by adding
// the daylight offset, if the zone says one applies right now.
//
// DateTime arithmetic is used rather than touching the hour field directly, so
// an offset that crosses midnight also rolls the day, month and year, and
// dayOfTheWeek() stays correct.
static DateTime standardToLocal(DstZone zone, const DateTime& stdTime) {
  uint8_t off = dstOffsetMinutes(zone, stdTime.year(), stdTime.month(),
                                 stdTime.day(), stdTime.hour(),
                                 stdTime.minute());
  if (off == 0) return stdTime;
  return stdTime + TimeSpan(0, 0, off, 0);
}

// Inverse of standardToLocal(): take the local wall time the user sees and work
// out what standard time to store.
//
// The rule is evaluated on the entered value read as standard time. This is
// exact everywhere except inside the one-hour window that a transition
// duplicates or skips, where local time is genuinely ambiguous and no answer is
// "right" - there, the reading lands on one side of the transition and the next
// automatic recalculation settles it.
static DateTime localToStandard(DstZone zone, const DateTime& local) {
  uint8_t off = dstOffsetMinutes(zone, local.year(), local.month(),
                                 local.day(), local.hour(), local.minute());
  if (off == 0) return local;
  return local - TimeSpan(0, 0, off, 0);
}

// Read the RTC and return local time. False if the RTC is absent or the read
// was implausible.
static bool readLocal(bool ready, DstZone zone, DateTime& out) {
  if (!ready) return false;
  DateTime t = rtc.now();
  if (!plausible(t)) return false;
  out = standardToLocal(zone, t);
  return true;
}

bool RealtimeClock::begin() {
  // Wire.begin() is expected to have been called already (Display does it).
  if (!rtc.begin()) {
    _ready = false;
    return false;
  }
  _ready = true;
  return true;
}

bool RealtimeClock::lostPower() {
  if (!_ready) return true;
  return rtc.lostPower();
}

bool RealtimeClock::powerReallyLost() {
  if (!_ready) return false;  // no RTC -> don't try to auto-write anything

  // Sample the power-loss flag several times. Only trust a "power lost"
  // result if every read agrees AND the time reads as invalid too. On a
  // glitching bus one read might lie; requiring unanimous agreement plus an
  // invalid time means a good clock is never overwritten by a transient fault.
  const uint8_t kSamples = 5;
  for (uint8_t i = 0; i < kSamples; i++) {
    if (!rtc.lostPower()) return false;  // any "not lost" read clears it
    delay(5);
  }

  // All reads said power was lost. Corroborate with the actual time: a truly
  // uninitialised DS3231 reads an invalid/nonsense date. If the time is valid
  // and in range, the flag is almost certainly a glitch, so keep the clock.
  DateTime t = rtc.now();
  if (plausible(t) && t.year() >= 2020) {
    return false;
  }
  return true;
}

bool RealtimeClock::dstActive() {
  if (!_ready || _dstZone == DstZone::Off) return false;
  DateTime t = rtc.now();
  if (!plausible(t)) return false;
  return isDstActive(_dstZone, t.year(), t.month(), t.day(), t.hour(),
                     t.minute());
}

void RealtimeClock::setDateTime(uint16_t year, uint8_t month, uint8_t day,
                                uint8_t hour, uint8_t minute, uint8_t second) {
  if (!_ready) return;
  // The caller passes local wall time; the hardware stores standard time.
  rtc.adjust(localToStandard(
      _dstZone, DateTime(year, month, day, hour, minute, second)));
}

void RealtimeClock::setToCompileTime() {
  if (!_ready) return;
  // __DATE__ / __TIME__ are the moment this file was compiled, in the build
  // host's local time - so it goes through the same local->standard reversal.
  rtc.adjust(localToStandard(_dstZone, DateTime(F(__DATE__), F(__TIME__))));
}

bool RealtimeClock::now(uint16_t& year, uint8_t& month, uint8_t& day,
                        uint8_t& hour, uint8_t& minute, uint8_t& second,
                        uint8_t& weekday) {
  DateTime t;
  if (!readLocal(_ready, _dstZone, t)) return false;

  year = t.year();
  month = t.month();
  day = t.day();
  hour = t.hour();
  minute = t.minute();
  second = t.second();
  weekday = t.dayOfTheWeek();
  return true;
}

String RealtimeClock::timeString(bool includeSeconds) {
  DateTime t;
  if (!readLocal(_ready, _dstZone, t)) {
    return String(includeSeconds ? "--:--:--" : "--:--");
  }

  char buf[9];
  if (includeSeconds) {
    snprintf(buf, sizeof(buf), "%02d:%02d:%02d", t.hour(), t.minute(),
             t.second());
  } else {
    snprintf(buf, sizeof(buf), "%02d:%02d", t.hour(), t.minute());
  }
  return String(buf);
}

String RealtimeClock::dateString() {
  DateTime t;
  if (!readLocal(_ready, _dstZone, t)) return String("----------");
  char buf[11];
  snprintf(buf, sizeof(buf), "%04d-%02d-%02d", t.year(), t.month(), t.day());
  return String(buf);
}


