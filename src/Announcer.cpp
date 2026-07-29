#include "Announcer.h"

bool Announcer::isBoundaryMinute(uint8_t minute) const {
  switch (_interval) {
    case AnnounceInterval::Off:
      return false;
    case AnnounceInterval::Hourly:
      return minute == 0;
    case AnnounceInterval::Half:
      return minute == 0 || minute == 30;
    case AnnounceInterval::Quarter:
      return minute % 15 == 0;  // 0, 15, 30, 45
    case AnnounceInterval::TestEveryMinute:
      return true;  // every minute (verification only)
  }
  return false;
}

bool Announcer::shouldAnnounce(uint8_t hour, uint8_t minute, uint8_t second) {
  if (_interval == AnnounceInterval::Off) return false;

  // Only consider the very start of the minute so we announce once, promptly.
  if (second != 0) {
    // Reset the guard once we've moved off the boundary minute, so the next
    // boundary can fire. (Guard is keyed on hour+minute below.)
    return false;
  }

  if (!isBoundaryMinute(minute)) return false;

  // Fire only once per (hour, minute) boundary.
  if (minute == _lastAnnouncedMinute && hour == _lastAnnouncedHour) {
    return false;
  }
  _lastAnnouncedMinute = minute;
  _lastAnnouncedHour = hour;
  return true;
}
