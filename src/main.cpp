/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 3: Read the time from the DS3231 RTC and show it on the OLED.
 * -------------------------------------------------------------------------
 * Goal of this stage:
 *   Initialise the RTC, read the current time, and render a clock face
 *   (weekday / big time / date) that updates every second.
 *
 * On first ever run (or after losing power with no battery), the RTC has no
 * valid time. We detect that with lostPower() and seed it from the sketch's
 * compile time so the display shows something sensible. Stage 4 will add
 * proper manual time setting.
 *
 * Wiring: OLED + DS3231 share the I2C bus (SDA=GPIO21, SCL=GPIO22),
 * both powered from 3V3. See docs/WIRING.md.
 *
 * Expected behaviour:
 *   - Serial (115200) prints init status and the time once per second.
 *   - The OLED shows weekday, a large HH:MM, and the date, ticking live.
 */

#include <Arduino.h>

#include "Display.h"
#include "RealtimeClock.h"

static const uint8_t LED_PIN = 2;

static Display display;
static RealtimeClock clock_;

// Track the last second we rendered so we only redraw when it changes.
static uint8_t lastSecond = 255;

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - Stage 3: RTC + display"));
  Serial.println(F("========================================"));

  // Display first: it calls Wire.begin() for the shared I2C bus.
  if (display.begin()) {
    Serial.println(F("OLED initialised OK."));
  } else {
    Serial.println(F("ERROR: OLED not found."));
  }

  if (clock_.begin()) {
    Serial.println(F("DS3231 RTC initialised OK."));

    if (clock_.lostPower()) {
      Serial.println(F("RTC lost power - seeding from compile time."));
      clock_.setToCompileTime();
    }
  } else {
    Serial.println(F("ERROR: DS3231 RTC not found."));
    display.showTwoLines("RTC error", "check wiring");
  }
}

void loop() {
  uint16_t year;
  uint8_t month, day, hour, minute, second, weekday;

  if (clock_.now(year, month, day, hour, minute, second, weekday)) {
    // Only redraw + log when the second actually changes.
    if (second != lastSecond) {
      lastSecond = second;

      display.showClock(clock_.weekdayString(),
                        clock_.timeString(false),
                        clock_.dateString());

      Serial.print(clock_.weekdayString());
      Serial.print(' ');
      Serial.print(clock_.dateString());
      Serial.print(' ');
      Serial.println(clock_.timeString(true));

      // Blink the LED each second as a heartbeat.
      digitalWrite(LED_PIN, second % 2 ? HIGH : LOW);
    }
  }

  delay(50);  // small poll interval; keeps the loop responsive
}
