/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 11: Settings menu + persistent storage.
 * -------------------------------------------------------------------------
 * The app is now a small state machine with two views:
 *   - Clock view: shows the time, speaks on demand, auto-announces.
 *   - Menu view : configure interval, quiet hours, volume, time, date, format.
 *
 * Controls (clock view):
 *   - BACK : speak the current time.
 *   - OK   : open the settings menu.
 * Controls (menu view): UP/DOWN navigate (hold to repeat), OK select/confirm,
 *   BACK go back/exit.
 *
 * Settings persist in flash (NVS) and are reloaded at boot.
 *
 * Wiring: see docs/WIRING.md.
 */

#include <Arduino.h>
#include <esp_task_wdt.h>

#include "Announcer.h"
#include "Audio.h"
#include "Buttons.h"
#include "Display.h"
#include "Menu.h"
#include "RealtimeClock.h"
#include "Settings.h"

// Stage 12: soak-test aids.
// Watchdog: if the loop ever hangs longer than this, the chip auto-resets.
static const uint32_t WDT_TIMEOUT_S = 30;
// Heartbeat: print uptime + free heap this often, to catch leaks/resets.
static const unsigned long HEARTBEAT_MS = 60000;

static const uint8_t LED_PIN = 2;

static Display display;
static RealtimeClock clock_;
static Audio audio;
static Buttons buttons;
static Announcer announcer;
static Settings settings;
static Menu menu(display, settings, announcer, clock_);

static uint8_t lastSecond = 255;
static bool audioReady = false;

// Remembers if OK was the button that interrupted speech, so the main loop can
// still act on it (open the menu) without needing a second press.
static bool pendingOpenMenu = false;

// Interrupt check for Audio: returns true if the user presses any button
// during speech, so playback aborts and the UI stays responsive.
bool anyButtonInterrupt() {
  buttons.update();
  bool ok = buttons.wasPressed(Button::Ok);
  bool other = buttons.wasPressed(Button::Back) ||
               buttons.wasPressed(Button::Up) ||
               buttons.wasPressed(Button::Down);
  if (ok) pendingOpenMenu = true;  // carry the intent out to the main loop
  return ok || other;
}

void speakNow() {
  if (!audioReady) return;
  uint16_t yr;
  uint8_t mo, dy, hh, mm, ss, wd;
  if (clock_.now(yr, mo, dy, hh, mm, ss, wd)) {
    Serial.print(F("Speaking: "));
    Serial.print(hh);
    Serial.print(':');
    Serial.println(mm);
    audio.speakTime(hh, mm, settings.use24h, languageOffset(settings.language));
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - Stage 11: settings menu"));
  Serial.println(F("========================================"));

  if (display.begin()) {
    Serial.println(F("OLED initialised OK."));
  } else {
    Serial.println(F("ERROR: OLED not found."));
  }

  if (clock_.begin()) {
    Serial.println(F("DS3231 RTC initialised OK."));
    if (clock_.lostPower()) clock_.setToCompileTime();
  } else {
    Serial.println(F("ERROR: DS3231 RTC not found."));
  }

  // Load persisted settings (or defaults on first boot).
  settings.load();

  if (audio.begin()) {
    audioReady = true;
    audio.setVolume(settings.volume);
    audio.setInterruptCheck(anyButtonInterrupt);  // press a button to stop speech
    Serial.println(F("DFPlayer initialised OK."));
  } else {
    Serial.println(F("WARNING: DFPlayer not responding."));
  }

  buttons.begin();

  // Apply loaded settings to the announcer.
  announcer.setInterval(settings.interval);
  announcer.setQuietHours(settings.quietEnabled, settings.quietStartH,
                          settings.quietStartM, settings.quietEndH,
                          settings.quietEndM);

  // Stage 12: enable the task watchdog on the loop task. If loop() ever fails
  // to check in within WDT_TIMEOUT_S, the chip resets and recovers on its own.
  esp_task_wdt_init(WDT_TIMEOUT_S, /*panic=*/true);
  esp_task_wdt_add(NULL);  // watch the current (loop) task

  Serial.println(F("Ready. BACK speaks the time; OK opens the menu."));
  Serial.print(F("Soak test: watchdog "));
  Serial.print(WDT_TIMEOUT_S);
  Serial.println(F("s, heartbeat every 60s."));
}

void loop() {
  buttons.update();

  if (menu.isActive()) {
    // ---- Menu view ----
    menu.handle(buttons);

    // When the menu exits, re-apply volume (it may have changed) and force a
    // clock redraw.
    if (!menu.isActive()) {
      audio.setVolume(settings.volume);
      lastSecond = 255;
    }
    delay(5);
    return;
  }

  // ---- Clock view ----

  // If OK was pressed to interrupt speech, honour that intent now by opening
  // the menu (no second press needed).
  if (pendingOpenMenu) {
    pendingOpenMenu = false;
    menu.open();
    delay(5);
    return;
  }

  // BACK speaks the current time; OK opens the settings menu.
  if (buttons.wasPressed(Button::Back)) {
    speakNow();
  }
  if (buttons.wasPressed(Button::Ok)) {
    menu.open();
    delay(5);
    return;  // start the menu cleanly next loop (no leaked events)
  }

  if (audioReady) audio.pollStatus();

  uint16_t year;
  uint8_t month, day, hour, minute, second, weekday;
  bool haveTime = clock_.now(year, month, day, hour, minute, second, weekday);

  // Automatic announcements at the configured interval (skipped in quiet hrs).
  if (haveTime && audioReady &&
      announcer.shouldAnnounce(hour, minute, second)) {
    Serial.print(F("Auto-announcing: "));
    Serial.print(hour);
    Serial.print(':');
    Serial.println(minute);
    audio.speakTime(hour, minute, settings.use24h,
                    languageOffset(settings.language));
  }

  if (haveTime && second != lastSecond) {
    lastSecond = second;
    bool quiet = announcer.isQuietNow(hour, minute);
    display.showClock(clock_.weekdayString(), clock_.timeString(false),
                      clock_.dateString(), quiet);
    digitalWrite(LED_PIN, second % 2 ? HIGH : LOW);
  }

  // Stage 12: heartbeat - print uptime, free heap, and the RTC time so a soak
  // log shows liveness, memory stability, and clock accuracy over time.
  static unsigned long lastBeat = 0;
  if (millis() - lastBeat >= HEARTBEAT_MS) {
    lastBeat = millis();
    Serial.print(F("[hb] up="));
    Serial.print(millis() / 1000);
    Serial.print(F("s heap="));
    Serial.print(ESP.getFreeHeap());
    Serial.print(F(" rtc="));
    Serial.println(clock_.timeString(true));
  }

  // Feed the watchdog so it knows the loop is healthy.
  esp_task_wdt_reset();

  delay(5);
}
