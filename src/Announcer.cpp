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

void Announcer::setQuietHours(bool enabled, uint8_t startHour, uint8_t startMin,
                              uint8_t endHour, uint8_t endMin) {
  _quietEnabled = enabled;
  _quietStart = (uint16_t)startHour * 60 + startMin;
  _quietEnd = (uint16_t)endHour * 60 + endMin;
}

bool Announcer::isQuietNow(uint8_t hour, uint8_t minute) const {
  if (!_quietEnabled) return false;
  uint16_t now = (uint16_t)hour * 60 + minute;

  if (_quietStart == _quietEnd) {
    // Zero-length window = never quiet.
    return false;
  }
  if (_quietStart < _quietEnd) {
    // Same-day window, e.g. 01:00 -> 06:00.
    return now >= _quietStart && now < _quietEnd;
  }
  // Overnight window that wraps midnight, e.g. 22:00 -> 08:00.
  return now >= _quietStart || now < _quietEnd;
}

bool Announcer::shouldAnnounce(uint8_t hour, uint8_t minute, uint8_t second) {
  // Release the guard as soon as the clock shows a minute other than the one we
  // last announced. This runs before every early return below, so the guard
  // still clears while muted, during quiet hours, or with the interval Off -
  // otherwise a stale latch could swallow the first boundary after those end.
  if (_fired && (hour != _firedHour || minute != _firedMinute)) {
    _fired = false;
  }

  if (_interval == AnnounceInterval::Off) return false;

  // Suppress automatic announcements during quiet hours (manual speech still
  // works, since that path does not call this method).
  if (isQuietNow(hour, minute)) return false;

  // Only consider the very start of the minute so we announce once, promptly.
  if (second != 0) return false;

  if (!isBoundaryMinute(minute)) return false;

  // Already spoken for this minute; wait for the clock to move on.
  if (_fired) return false;

  _fired = true;
  _firedHour = hour;
  _firedMinute = minute;
  return true;
}
