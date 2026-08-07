/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * The app is a small state machine with two views:
 *   - Clock view: shows the time, speaks on demand, auto-announces, and plays
 *                 a playful panda reaction on the arrow buttons.
 *   - Menu view : configure interval, quiet hours, volume, time, date, format,
 *                 language.
 *
 * Input is a single KY-023 thumbstick. Buttons.h maps it to four logical
 * actions - stick up/down, left = BACK, right or a press = OK - so everything
 * below is written in terms of those actions, not the hardware.
 *
 * Controls (clock view):
 *   - BACK  (stick left)        : tap speaks the current time, hold mutes.
 *   - OK    (press or right)    : open the settings menu.
 *   - UP/DOWN                   : panda reaction animation (eye-candy).
 * Controls (menu view): UP/DOWN navigate (hold to repeat), OK select/confirm,
 *   BACK go back/exit.
 *
 * Settings persist in flash (NVS) and are reloaded at boot. A panda-themed
 * animated splash plays at startup.
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
#include "Localization.h"

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
  Serial.println(F("  Vocetempo - panda-themed talking clock"));
  Serial.println(F("========================================"));

  if (display.begin()) {
    Serial.println(F("OLED initialised OK."));
    display.showBootSplash();  // panda-themed animated splash
  } else {
    Serial.println(F("ERROR: OLED not found."));
  }

  bool rtcReady = clock_.begin();
  if (rtcReady) {
    Serial.println(F("DS3231 RTC initialised OK."));
  } else {
    Serial.println(F("ERROR: DS3231 RTC not found."));
  }

  // Load persisted settings (or defaults on first boot).
  settings.load();

  // The DST zone must be applied BEFORE any clock read or write, because it
  // decides how the RTC's stored standard time is interpreted. Seeding from
  // compile time below is a write, so it has to come after this.
  clock_.setDstZone(settings.dstZone);
  if (settings.dstZone != DstZone::Off) {
    Serial.print(F("DST zone: "));
    Serial.print(dstZoneName(settings.dstZone));
    Serial.println(clock_.dstActive() ? F(" (summer time active)")
                                      : F(" (standard time)"));
  }

  if (rtcReady) {
    // Only auto-set the clock if power was *really* lost (debounced across
    // several reads + corroborated by an invalid time). This prevents a
    // glitching I2C bus from tricking us into overwriting a clock that is
    // actually keeping good time. Deliberate time changes go through the menu.
    if (clock_.powerReallyLost()) {
      Serial.println(F("RTC power was lost; seeding from compile time."));
      clock_.setToCompileTime();
    }
  }

  if (audio.begin()) {
    audioReady = true;
    audio.setVolume(settings.volume);
    audio.setInterruptCheck(anyButtonInterrupt);  // press a button to stop speech
    Serial.println(F("DFPlayer initialised OK."));
  } else {
    Serial.println(F("WARNING: DFPlayer not responding."));
  }

  buttons.begin();
  // Report the stick's measured resting point. If calibration was rejected the
  // user was probably holding it at boot, or an axis is not connected - either
  // way the deadzone falls back to nominal and the log says so rather than
  // leaving a mystery. tools/joystick_test gives the full picture.
  Serial.print(F("Joystick centre: x="));
  Serial.print(buttons.centreX());
  Serial.print(F(" y="));
  Serial.print(buttons.centreY());
  if (buttons.calibrated()) {
    Serial.println(F(" (calibrated)"));
  } else {
    Serial.print(F(" (NOT calibrated - resting read x="));
    Serial.print(buttons.rawX());
    Serial.print(F(" y="));
    Serial.print(buttons.rawY());
    Serial.println(F("; stick held at boot or an axis unwired?)"));
  }

  // Apply loaded settings to the announcer.
  announcer.setInterval(settings.interval);
  announcer.setQuietHours(settings.quietEnabled, settings.quietStartH,
                          settings.quietStartM, settings.quietEndH,
                          settings.quietEndM);

  // Stage 12: enable the task watchdog on the loop task. If loop() ever fails
  // to check in within WDT_TIMEOUT_S, the chip resets and recovers on its own.
  esp_task_wdt_init(WDT_TIMEOUT_S, /*panic=*/true);
  esp_task_wdt_add(NULL);  // watch the current (loop) task

  Serial.println(F("Ready. Stick LEFT taps to speak, hold to mute; press or "
                   "RIGHT opens the menu; UP/DOWN pet the panda."));
  Serial.print(F("Soak test: watchdog "));
  Serial.print(WDT_TIMEOUT_S);
  Serial.println(F("s, heartbeat every 60s."));
}

// How long BACK must be held (ms) on the clock face to toggle mute.
static const unsigned long MUTE_HOLD_MS = 800;
// How long the interactive panda screen waits with no input before returning.
static const unsigned long PANDA_IDLE_TIMEOUT_MS = 6000;

// Interactive "pet the panda" screen. Stays up reacting to buttons: UP waves
// the right paw, DOWN the left, OK a happy bounce; each pet adds a heart (max
// 5). The panda blinks on its own while idle. Returns on BACK or after a few
// seconds of no input. Blocking, but feeds the watchdog throughout.
static void runPandaMode(bool startWaveRight) {
  // A few rotating captions so repeated petting stays fun.
  static const char* const kPetCaptions[] = {"Hi!", "Hehe", "Yay!", "Boop",
                                              "Panda!"};
  static const uint8_t kNumCaptions = 5;

  uint8_t hearts = 1;
  uint8_t capIdx = 0;
  // Paw side follows the direction pushed: UP -> left paw, DOWN -> right paw.
  // `startWaveRight` is true when entered via UP; we invert it here so the
  // waving paw matches the way the stick was moved.
  Panda::Pose pose = startWaveRight ? Panda::Pose::WaveLeft
                                    : Panda::Pose::WaveRight;

  unsigned long lastInteract = millis();
  unsigned long lastBlink = millis();

  display.showPandaFrame(pose, hearts, kPetCaptions[capIdx]);

  while (true) {
    buttons.update();
    esp_task_wdt_reset();

    bool up = buttons.wasPressed(Button::Up);
    bool down = buttons.wasPressed(Button::Down);
    bool ok = buttons.wasPressed(Button::Ok);
    bool back = buttons.wasPressed(Button::Back);

    if (back) break;  // BACK leaves the panda screen

    if (up || down || ok) {
      lastInteract = millis();
      if (hearts < 16) hearts++;  // matches Display's side-column heart layout
      capIdx = (capIdx + 1) % kNumCaptions;
      // UP -> left paw, DOWN -> right paw (mirrors the stick's movement).
      if (up) pose = Panda::Pose::WaveLeft;
      else if (down) pose = Panda::Pose::WaveRight;
      else pose = Panda::Pose::Happy;

      // A quick two-step bounce so the reaction feels lively, not static.
      display.showPandaFrame(pose, hearts, kPetCaptions[capIdx]);
      delay(120);
      display.showPandaFrame(Panda::Pose::Blink, hearts, kPetCaptions[capIdx]);
      delay(90);
      display.showPandaFrame(pose, hearts, kPetCaptions[capIdx]);
      lastBlink = millis();
    } else if (millis() - lastBlink > 2500) {
      // Idle blink to keep the panda feeling alive.
      lastBlink = millis();
      display.showPandaFrame(Panda::Pose::Blink, hearts, "");
      delay(120);
      display.showPandaFrame(Panda::Pose::Happy, hearts, "");
    }

    if (millis() - lastInteract > PANDA_IDLE_TIMEOUT_MS) break;
    delay(10);
  }

  lastSecond = 255;      // force a clock redraw when we return
  esp_task_wdt_reset();
}

// Stage 12: heartbeat - print uptime, free heap, and the RTC time so a soak log
// shows liveness, memory stability, and clock accuracy over time.
//
// Called from the TOP of loop(), before the menu early-return, so a clock left
// sitting in a menu overnight still proves it is alive. With this at the bottom
// of loop() the log went completely silent whenever a menu was open, which is
// indistinguishable from a crash in a soak log.
static void heartbeat() {
  static unsigned long lastBeat = 0;
  if (millis() - lastBeat < HEARTBEAT_MS) return;
  lastBeat = millis();
  Serial.print(F("[hb] up="));
  Serial.print(millis() / 1000);
  Serial.print(F("s heap="));
  Serial.print(ESP.getFreeHeap());
  Serial.print(F(" rtc="));
  Serial.println(clock_.timeString(true));
}

void loop() {
  buttons.update();
  heartbeat();

  if (menu.isActive()) {
    // ---- Menu view ----
    menu.handle(buttons);

    // When the menu exits, re-apply volume (it may have changed) and force a
    // clock redraw.
    if (!menu.isActive()) {
      audio.setVolume(settings.volume);
      lastSecond = 255;
    }
    // The menu is a legitimately long-lived state - a user can sit on a screen
    // for minutes - so it must feed the watchdog itself. This return skips the
    // reset at the bottom of loop(), so without this line the 30s watchdog
    // could reset the clock while someone was simply reading a settings page.
    esp_task_wdt_reset();
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

  // BACK: a short tap speaks the time; a long hold toggles mute. We track the
  // press here and act either when the hold threshold is crossed (mute) or on
  // release before that (speak). Booleans below are read once each - remember
  // wasPressed() consumes the edge.
  static bool backHolding = false;      // BACK is currently held down
  static bool backHoldHandled = false;  // the hold already toggled mute
  static unsigned long backPressStart = 0;

  if (buttons.wasPressed(Button::Back)) {
    backHolding = true;
    backHoldHandled = false;
    backPressStart = millis();
  }
  if (backHolding) {
    if (buttons.isDown(Button::Back)) {
      // Still held: has it crossed the mute-toggle threshold?
      if (!backHoldHandled && millis() - backPressStart >= MUTE_HOLD_MS) {
        backHoldHandled = true;
        settings.muted = !settings.muted;
        settings.save();
        Serial.print(F("Mute toggled -> "));
        Serial.println(settings.muted ? F("MUTED") : F("unmuted"));
        // On-theme confirmation: the panda covers its ears (blink) when muted,
        // or waves happily when unmuted.
        display.showPandaFrame(
            settings.muted ? Panda::Pose::Blink : Panda::Pose::Happy, 0,
            tr(settings.muted ? Str::Muted : Str::SoundOn, settings.language));
        delay(900);
        lastSecond = 255;  // redraw clock (with/without mute icon) next tick
        esp_task_wdt_reset();
      }
    } else {
      // Released. If the hold never toggled mute, treat it as a tap -> speak.
      backHolding = false;
      if (!backHoldHandled) speakNow();
    }
  }

  if (buttons.wasPressed(Button::Ok)) {
    menu.open();
    delay(5);
    return;  // start the menu cleanly next loop (no leaked events)
  }

  // UP / DOWN on the clock face open the interactive "pet the panda" screen.
  // Read each edge once into a local first: wasPressed() consumes the edge.
  bool upPressed = buttons.wasPressed(Button::Up);
  bool downPressed = buttons.wasPressed(Button::Down);
  if (upPressed || downPressed) {
    runPandaMode(/*startWaveRight=*/upPressed);
  }

  if (audioReady) audio.pollStatus();

  uint16_t year;
  uint8_t month, day, hour, minute, second, weekday;
  bool haveTime = clock_.now(year, month, day, hour, minute, second, weekday);

  // I2C fault recovery: if time reads keep failing (a glitching bus/loose
  // wire), the RTC and OLED share the bus, so recover it instead of flooding
  // errors. After several consecutive bad reads, re-init the bus + display.
  static uint16_t badReads = 0;
  if (!haveTime) {
    badReads++;
    if (badReads >= 20) {  // ~ several hundred ms of failures
      Serial.println(F("I2C fault: attempting bus/display recovery..."));
      display.recover();
      badReads = 0;
    }
  } else {
    badReads = 0;
  }

  // Update the clock face FIRST, before any (blocking) announcement. Otherwise
  // speakTime() would hold the loop for the whole 5-10s phrase and the OLED
  // would only catch up to the new minute after the voice finished - so the
  // voice appeared to "run ahead" of the screen by several seconds.
  if (haveTime && second != lastSecond) {
    lastSecond = second;
    bool quiet = announcer.isQuietNow(hour, minute);
    // Weekday name is localized to the selected language (audio + on-screen
    // text stay in sync). We pass the raw day-of-week we already read.
    display.showClock(weekdayName(weekday, settings.language),
                      clock_.timeString(false), clock_.dateString(), quiet,
                      settings.muted);
    digitalWrite(LED_PIN, second % 2 ? HIGH : LOW);
  }

  // Automatic announcements at the configured interval (skipped in quiet hours
  // and when muted). shouldAnnounce() is asked on every good time read, even
  // while muted or without audio, so its once-per-boundary guard keeps
  // following the clock and cannot go stale; the checks below decide whether to
  // act on the answer. This runs AFTER the display update above so the screen
  // already shows the new time.
  bool announceDue = haveTime && announcer.shouldAnnounce(hour, minute, second);
  if (announceDue && audioReady && !settings.muted) {
    Serial.print(F("Auto-announcing: "));
    Serial.print(hour);
    Serial.print(':');
    Serial.println(minute);
    audio.speakTime(hour, minute, settings.use24h,
                    languageOffset(settings.language));
  }

  // Feed the watchdog so it knows the loop is healthy.
  esp_task_wdt_reset();

  delay(5);
}
