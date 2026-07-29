/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 7: Read the four push buttons (debounced).
 * -------------------------------------------------------------------------
 * Goal of this stage:
 *   Verify all four buttons (UP/DOWN/OK/BACK) register clean, single presses.
 *   Each press is printed to Serial and briefly shown on the OLED. As a
 *   preview of Stage 8, pressing OK speaks the test clip.
 *
 * Wiring (see docs/WIRING.md): each button connects its GPIO to GND.
 *   UP=32  DOWN=33  OK=25  BACK=26   (internal pull-ups, active-low)
 *
 * Expected behaviour:
 *   - Clock shows on the OLED as usual.
 *   - Pressing any button prints e.g. "Button pressed: UP" once per press
 *     (no repeats/bounce) and flashes the name on screen.
 *   - Pressing OK also plays "It is".
 */

#include <Arduino.h>

#include "Audio.h"
#include "Buttons.h"
#include "Display.h"
#include "RealtimeClock.h"

static const uint8_t LED_PIN = 2;

static Display display;
static RealtimeClock clock_;
static Audio audio;
static Buttons buttons;

static uint8_t lastSecond = 255;
static bool audioReady = false;

// When non-zero, show this button name on the OLED until the given millis().
static const char* flashName = nullptr;
static unsigned long flashUntil = 0;

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - Stage 7: buttons"));
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

  if (audio.begin()) {
    audioReady = true;
    audio.setVolume(18);
    Serial.println(F("DFPlayer initialised OK."));
  } else {
    Serial.println(F("WARNING: DFPlayer not responding (OK button won't speak)."));
  }

  buttons.begin();
  Serial.println(F("Buttons ready. Press UP/DOWN/OK/BACK to test."));
}

void handleButton(Button b, const char* name) {
  if (buttons.wasPressed(b)) {
    // Rate-limit prints so a flaky contact can never flood the serial line.
    static unsigned long lastPrint = 0;
    if (millis() - lastPrint > 150) {
      lastPrint = millis();
      Serial.print(F("Button pressed: "));
      Serial.println(name);
    }
    flashName = name;
    flashUntil = millis() + 800;

    // Stage 8: OK speaks the current time.
    if (b == Button::Ok && audioReady) {
      uint16_t yr;
      uint8_t mo, dy, hh, mm, ss, wd;
      if (clock_.now(yr, mo, dy, hh, mm, ss, wd)) {
        Serial.print(F("Speaking time: "));
        Serial.print(hh);
        Serial.print(':');
        Serial.println(mm);
        audio.speakTime(hh, mm, /*use24h=*/false);
      }
    }
  }
}

void loop() {
  buttons.update();

  handleButton(Button::Up, "UP");
  handleButton(Button::Down, "DOWN");
  handleButton(Button::Ok, "OK");
  handleButton(Button::Back, "BACK");

  if (audioReady) audio.pollStatus();

  // Update the display roughly once per second, or immediately to show a
  // button flash.
  uint16_t year;
  uint8_t month, day, hour, minute, second, weekday;
  bool haveTime = clock_.now(year, month, day, hour, minute, second, weekday);

  bool flashing = flashName && millis() < flashUntil;

  static bool wasFlashing = false;
  if (flashing) {
    // Show the pressed button name prominently.
    display.showTwoLines("Button:", flashName);
    wasFlashing = true;
  } else {
    if (wasFlashing) {
      // Flash just ended - force a clock redraw.
      lastSecond = 255;
      wasFlashing = false;
      flashName = nullptr;
    }
    if (haveTime && second != lastSecond) {
      lastSecond = second;
      display.showClock(clock_.weekdayString(), clock_.timeString(false),
                        clock_.dateString());
      digitalWrite(LED_PIN, second % 2 ? HIGH : LOW);
    }
  }

  delay(5);  // keep the loop fast so button sampling stays responsive
}
