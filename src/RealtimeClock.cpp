#include "RealtimeClock.h"

#include <RTClib.h>

// The RTClib driver instance, kept file-local.
static RTC_DS3231 rtc;

// Full weekday names indexed by DateTime::dayOfTheWeek() (0 = Sunday).
static const char* const kWeekdays[] = {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"};

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

void RealtimeClock::setDateTime(uint16_t year, uint8_t month, uint8_t day,
                                uint8_t hour, uint8_t minute, uint8_t second) {
  if (!_ready) return;
  rtc.adjust(DateTime(year, month, day, hour, minute, second));
}

void RealtimeClock::setToCompileTime() {
  if (!_ready) return;
  // __DATE__ / __TIME__ are the moment this file was compiled.
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

bool RealtimeClock::now(uint16_t& year, uint8_t& month, uint8_t& day,
                        uint8_t& hour, uint8_t& minute, uint8_t& second,
                        uint8_t& weekday) {
  if (!_ready) return false;
  DateTime t = rtc.now();

  // Reject obviously corrupt reads (e.g. from a glitching I2C bus). RTClib's
  // isValid() checks the fields parse to a sane date; we also bound-check the
  // ranges defensively so a garbage read never propagates into the UI or an
  // announcement.
  if (!t.isValid() || t.hour() > 23 || t.minute() > 59 || t.second() > 59 ||
      t.month() < 1 || t.month() > 12 || t.day() < 1 || t.day() > 31) {
    return false;
  }

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
  if (!_ready) return String("--:--");
  DateTime t = rtc.now();

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
  if (!_ready) return String("-------_--");
  DateTime t = rtc.now();
  char buf[11];
  snprintf(buf, sizeof(buf), "%04d-%02d-%02d", t.year(), t.month(), t.day());
  return String(buf);
}

String RealtimeClock::weekdayString() {
  if (!_ready) return String("---");
  DateTime t = rtc.now();
  uint8_t dow = t.dayOfTheWeek();
  if (dow > 6) return String("---");
  return String(kWeekdays[dow]);
}
