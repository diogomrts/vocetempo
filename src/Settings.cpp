#include "Settings.h"

#include <Preferences.h>

// NVS namespace for all Vocetempo settings.
static const char* kNamespace = "vocetempo";

void Settings::load() {
  Preferences prefs;
  prefs.begin(kNamespace, /*readOnly=*/true);

  interval = static_cast<AnnounceInterval>(
      prefs.getUChar("interval", static_cast<uint8_t>(interval)));

  quietEnabled = prefs.getBool("qEnabled", quietEnabled);
  quietStartH = prefs.getUChar("qStartH", quietStartH);
  quietStartM = prefs.getUChar("qStartM", quietStartM);
  quietEndH = prefs.getUChar("qEndH", quietEndH);
  quietEndM = prefs.getUChar("qEndM", quietEndM);

  volume = prefs.getUChar("volume", volume);
  use24h = prefs.getBool("use24h", use24h);
  language = static_cast<Language>(
      prefs.getUChar("lang", static_cast<uint8_t>(language)));

  prefs.end();
}

void Settings::save() {
  Preferences prefs;
  prefs.begin(kNamespace, /*readOnly=*/false);

  prefs.putUChar("interval", static_cast<uint8_t>(interval));

  prefs.putBool("qEnabled", quietEnabled);
  prefs.putUChar("qStartH", quietStartH);
  prefs.putUChar("qStartM", quietStartM);
  prefs.putUChar("qEndH", quietEndH);
  prefs.putUChar("qEndM", quietEndM);

  prefs.putUChar("volume", volume);
  prefs.putBool("use24h", use24h);
  prefs.putUChar("lang", static_cast<uint8_t>(language));

  prefs.end();
}
