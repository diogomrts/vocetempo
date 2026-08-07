/*
 * Localization - on-screen text localization (EN / PT / ES).
 *
 * Every user-facing label the UI draws goes through here so that changing the
 * language (in Settings) switches the on-screen text as well as the spoken
 * audio. One enum of string IDs + one table per language keeps it simple and
 * keeps all translations in a single place.
 *
 * NOTE on accents: the Adafruit GFX default font only renders ASCII reliably,
 * so these on-screen strings are deliberately accent-free (e.g. "Terca",
 * "Sabado"). The spoken audio still uses fully correct, accented pronunciation
 * - that lives in the pre-rendered phrase files, not here.
 *
 * (Named Localization, not Strings: macOS's case-insensitive filesystem would
 * confuse a "Strings.h" with the C library header <string.h>.)
 */

#ifndef VOCETEMPO_LOCALIZATION_H
#define VOCETEMPO_LOCALIZATION_H

#include <Arduino.h>

#include "Settings.h"  // for Language

// Identifiers for every localizable piece of text.
enum class Str : uint8_t {
  // Clock-face status.
  Muted,
  SoundOn,

  // Menu title + items (order is independent of the menu's own indexing).
  MenuTitle,
  Announce,
  QuietStart,
  QuietEnd,
  Volume,
  SetTime,
  SetDate,
  Dst,
  Format,
  Language,
  Controls,
  Exit,

  // Announcement interval values.
  IntervalOff,
  IntervalHourly,
  IntervalHalf,
  IntervalQuarter,

  // Time format values.
  Format24h,
  Format12h,

  // Controls / help screen rows. Kept to a couple of words each so they still
  // fit beside their icon once translated.
  CtrlMove,      // stick up/down
  CtrlSelect,    // stick right, or press it
  CtrlBack,      // stick left
  CtrlSpeak,     // tap left on the clock face
  CtrlMute,      // hold left on the clock face

  // Edit-screen hints.
  HintSave,      // change value, then save
  HintHour,      // editing the hour field
  HintMin,       // editing the minute field
  HintYear,      // editing the year field
  HintMon,       // editing the month field
  HintDay,       // editing the day field

  Count
};

// Return the localized text for `id` in `lang`. Never returns nullptr.
const char* tr(Str id, Language lang);

// Localized full weekday name. `dow` is 0=Sunday .. 6=Saturday. Out-of-range
// returns "---".
const char* weekdayName(uint8_t dow, Language lang);

#endif  // VOCETEMPO_LOCALIZATION_H
