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

  // Load values from NVS (falls back to the defaults above if unset).
  void load();

  // Persist all values to NVS.
  void save();
};

#endif  // VOCETEMPO_SETTINGS_H
