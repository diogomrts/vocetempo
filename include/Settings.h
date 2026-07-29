/*
 * Settings - persistent user configuration stored in ESP32 flash (NVS via the
 * Preferences library).
 *
 * Holds everything the user can configure. Call load() once at boot and save()
 * whenever a value changes so settings survive power loss.
 *
 * Note: the current time/date live in the DS3231 RTC, not here - the menu
 * writes those directly to the RTC. This class stores behaviour preferences.
 */

#ifndef VOCETEMPO_SETTINGS_H
#define VOCETEMPO_SETTINGS_H

#include <Arduino.h>

#include "Announcer.h"  // for AnnounceInterval

// Speech language. The value maps to a file-index offset in /mp3:
//   English 0, Portuguese 2000, Spanish 4000 (see audio/generate_multilang.py).
enum class Language : uint8_t { English, Portuguese, Spanish };

// File-index offset for a language's phrase set in /mp3.
inline uint16_t languageOffset(Language lang) {
  switch (lang) {
    case Language::Portuguese: return 2000;
    case Language::Spanish: return 4000;
    case Language::English:
    default: return 0;
  }
}

// Short display name for a language.
inline const char* languageName(Language lang) {
  switch (lang) {
    case Language::Portuguese: return "Portugues";
    case Language::Spanish: return "Espanol";
    case Language::English:
    default: return "English";
  }
}

struct Settings {
  // Announcement behaviour.
  AnnounceInterval interval = AnnounceInterval::Hourly;

  // Quiet hours.
  bool quietEnabled = true;
  uint8_t quietStartH = 22;
  uint8_t quietStartM = 0;
  uint8_t quietEndH = 8;
  uint8_t quietEndM = 0;

  // Audio.
  uint8_t volume = 18;  // 0..30

  // Display / speech format.
  bool use24h = false;

  // Speech language.
  Language language = Language::English;

  // Load values from NVS (falls back to the defaults above if unset).
  void load();

  // Persist all values to NVS.
  void save();
};

#endif  // VOCETEMPO_SETTINGS_H
