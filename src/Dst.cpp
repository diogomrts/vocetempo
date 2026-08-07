#include "Dst.h"

// A DST rule for one region.
//
// startHourStd is the transition hour in local STANDARD time; endHourDst is the
// transition hour in local DAYLIGHT time. See the header for why the two
// boundaries use different bases.
struct DstRule {
  uint8_t startMonth;
  int8_t startNth;  // 1..5 = nth weekday of the month, -1 = last
  uint8_t startWeekday;
  uint8_t startHourStd;

  uint8_t endMonth;
  int8_t endNth;
  uint8_t endWeekday;
  uint8_t endHourDst;

  uint8_t offsetMinutes;
};

// Rules indexed by DstZone, so the table order must match the enum exactly.
// Index 0 (Off) is a zero rule and never consulted.
//
// Sunday == 0 throughout.
static const DstRule kRules[static_cast<uint8_t>(DstZone::Count)] = {
    // Off - unused placeholder.
    {0, 0, 0, 0, 0, 0, 0, 0, 0},

    // Europe switches simultaneously across the union at 01:00 UTC, which is a
    // different local hour in each of its three zones - hence three entries
    // whose only difference is the hour. Start 01:00 UTC, end 01:00 UTC.
    // EuropeWest (UTC+0): 01:00 GMT -> 02:00 BST; 02:00 BST -> 01:00 GMT.
    {3, -1, 0, 1, 10, -1, 0, 2, 60},
    // EuropeCentral (UTC+1): 02:00 CET -> 03:00 CEST; 03:00 CEST -> 02:00 CET.
    {3, -1, 0, 2, 10, -1, 0, 3, 60},
    // EuropeEast (UTC+2): 03:00 EET -> 04:00 EEST; 04:00 EEST -> 03:00 EET.
    {3, -1, 0, 3, 10, -1, 0, 4, 60},

    // North America (US Energy Policy Act 2005, matched by Canada): second
    // Sunday in March at 02:00 standard, first Sunday in November at 02:00
    // daylight. Local-clock based, so one rule covers every zone from
    // Newfoundland to the Pacific.
    {3, 2, 0, 2, 11, 1, 0, 2, 60},

    // Chile: starts the first Saturday of September at 24:00 (= Sunday 00:00)
    // standard, ends the first Saturday of April at 24:00 daylight (= Sunday
    // 00:00 daylight, i.e. 23:00 Saturday standard).
    {9, 1, 0, 0, 4, 1, 0, 0, 60},

    // Australia (NSW/VIC/SA/TAS/ACT): first Sunday in October at 02:00
    // standard, first Sunday in April at 03:00 daylight.
    {10, 1, 0, 2, 4, 1, 0, 3, 60},

    // New Zealand: last Sunday in September at 02:00 standard, first Sunday in
    // April at 03:00 daylight.
    {9, -1, 0, 2, 4, 1, 0, 3, 60},
};

static const char* const kZoneNames[static_cast<uint8_t>(DstZone::Count)] = {
    "Off", "UK/Portugal", "Europe CET",   "Europe EET",
    "USA/Canada", "Chile", "Australia SE", "New Zealand",
};

const char* dstZoneName(DstZone zone) {
  uint8_t i = static_cast<uint8_t>(zone);
  if (i >= static_cast<uint8_t>(DstZone::Count)) return "Off";
  return kZoneNames[i];
}

uint8_t daysInMonth(uint16_t year, uint8_t month) {
  static const uint8_t kDays[12] = {31, 28, 31, 30, 31, 30,
                                    31, 31, 30, 31, 30, 31};
  if (month < 1 || month > 12) return 31;
  if (month == 2 &&
      ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
    return 29;
  }
  return kDays[month - 1];
}

int32_t daysFromCivil(uint16_t year, uint8_t month, uint8_t day) {
  // Howard Hinnant's days_from_civil: shifts the year to start in March so
  // that the leap day lands at the end of the year and needs no special case.
  int32_t y = static_cast<int32_t>(year);
  y -= (month <= 2) ? 1 : 0;
  const int32_t era = (y >= 0 ? y : y - 399) / 400;
  const uint32_t yoe = static_cast<uint32_t>(y - era * 400);  // [0, 399]
  const uint32_t doy =
      (153u * (month + (month > 2 ? -3 : 9)) + 2u) / 5u + day - 1u;  // [0, 365]
  const uint32_t doe = yoe * 365u + yoe / 4u - yoe / 100u + doy;  // [0, 146096]
  return era * 146097L + static_cast<int32_t>(doe) - 719468L;
}

uint8_t weekdayOf(uint16_t year, uint8_t month, uint8_t day) {
  // 1970-01-01 (day 0) was a Thursday, which is index 4 with Sunday == 0.
  int32_t z = daysFromCivil(year, month, day);
  int32_t w = (z + 4) % 7;
  if (w < 0) w += 7;
  return static_cast<uint8_t>(w);
}

uint8_t nthWeekdayOfMonth(uint16_t year, uint8_t month, uint8_t weekday,
                          int8_t nth) {
  if (month < 1 || month > 12 || weekday > 6) return 0;
  const uint8_t last = daysInMonth(year, month);

  if (nth < 0) {
    // Walk back from the end of the month to the requested weekday.
    uint8_t wdLast = weekdayOf(year, month, last);
    uint8_t back = (wdLast + 7u - weekday) % 7u;
    return last - back;
  }
  if (nth < 1) return 0;

  uint8_t wdFirst = weekdayOf(year, month, 1);
  uint8_t forward = (weekday + 7u - wdFirst) % 7u;
  uint16_t d = 1u + forward + (static_cast<uint16_t>(nth) - 1u) * 7u;
  if (d > last) return 0;  // that occurrence does not exist this month
  return static_cast<uint8_t>(d);
}

// Linear minutes since 1970-01-01T00:00 for a date plus a minute-of-day that
// may be negative or exceed a day. Keeping the boundaries on one linear scale
// is what lets an end boundary fall before midnight without special cases.
static int64_t minutesFromCivil(uint16_t year, uint8_t month, uint8_t day,
                                int32_t minuteOfDay) {
  return static_cast<int64_t>(daysFromCivil(year, month, day)) * 1440LL +
         static_cast<int64_t>(minuteOfDay);
}

bool isDstActive(DstZone zone, uint16_t year, uint8_t month, uint8_t day,
                 uint8_t hour, uint8_t minute) {
  const uint8_t zi = static_cast<uint8_t>(zone);
  if (zone == DstZone::Off || zi >= static_cast<uint8_t>(DstZone::Count)) {
    return false;
  }
  // Defensive: a corrupt RTC read must not shift the clock.
  if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 ||
      minute > 59) {
    return false;
  }

  const DstRule& r = kRules[zi];

  const uint8_t startDay =
      nthWeekdayOfMonth(year, r.startMonth, r.startWeekday, r.startNth);
  const uint8_t endDay =
      nthWeekdayOfMonth(year, r.endMonth, r.endWeekday, r.endNth);
  if (startDay == 0 || endDay == 0) return false;  // malformed rule

  const int64_t now =
      minutesFromCivil(year, month, day,
                       static_cast<int32_t>(hour) * 60 + minute);
  const int64_t start = minutesFromCivil(
      year, r.startMonth, startDay, static_cast<int32_t>(r.startHourStd) * 60);
  // The end boundary is legislated in daylight time; convert it to the
  // standard-time scale the RTC uses. This can go before midnight (Chile),
  // which the linear scale absorbs.
  const int64_t end = minutesFromCivil(
      year, r.endMonth, endDay,
      static_cast<int32_t>(r.endHourDst) * 60 - r.offsetMinutes);

  if (start < end) {
    // Northern hemisphere: the daylight period sits inside the year.
    return now >= start && now < end;
  }
  // Southern hemisphere: the daylight period wraps the year end, so a date is
  // in it if it is after this year's start OR before this year's end.
  return now >= start || now < end;
}

uint8_t dstOffsetMinutes(DstZone zone, uint16_t year, uint8_t month,
                         uint8_t day, uint8_t hour, uint8_t minute) {
  if (!isDstActive(zone, year, month, day, hour, minute)) return 0;
  return kRules[static_cast<uint8_t>(zone)].offsetMinutes;
}
