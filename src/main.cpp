/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 5: Connect the DFPlayer and play one test audio clip.
 * -------------------------------------------------------------------------
 * Goal of this stage:
 *   Bring up the DFPlayer Mini over UART and play /mp3/0001.mp3 ("It is")
 *   through the speaker, proving the audio subsystem works. The clock from
 *   Stage 3 keeps running on the OLED throughout.
 *
 * Wiring (see docs/WIRING.md):
 *   OLED + RTC on I2C (SDA 21, SCL 22, 3V3).
 *   DFPlayer:  VCC->5V(VIN), GND->gnd, RX<-GPIO27 (via 1k), TX->GPIO14.
 *   Speaker across SPK_1 / SPK_2. microSD in the DFPlayer.
 *
 * Expected behaviour:
 *   - Serial (115200) prints init status for OLED, RTC, and DFPlayer.
 *   - Shortly after boot, the speaker says "It is".
 *   - The OLED keeps showing the live clock.
 *   - DFPlayer status messages are printed as they arrive.
 */

#include <Arduino.h>

#include "Audio.h"
#include "Display.h"
#include "RealtimeClock.h"

static const uint8_t LED_PIN = 2;

static Display display;
static RealtimeClock clock_;
static Audio audio;

static uint8_t lastSecond = 255;
static bool playedTestClip = false;
static bool audioReady = false;

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - Stage 5: DFPlayer audio"));
  Serial.println(F("========================================"));

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
  }

  Serial.println(F("Initialising DFPlayer (a few seconds)..."));
  if (audio.begin()) {
    audioReady = true;
    Serial.println(F("DFPlayer initialised OK."));
    audio.setVolume(30);  // 0..30; max volume for bring-up loudness test
  } else {
    Serial.println(F("ERROR: DFPlayer not responding."));
    Serial.println(F("Check: 5V power, RX/TX (crossed) on 27/14, card inserted."));
  }
}

void loop() {
  // Once, a moment after boot, play the test clip.
  if (audioReady && !playedTestClip && millis() > 3000) {
    Serial.println(F("Playing test clip 0001.mp3 (\"It is\")..."));
    audio.playIndex(1);
    playedTestClip = true;
  }

  // Surface any DFPlayer status/error messages.
  if (audioReady) audio.pollStatus();

  // Keep the clock ticking on the OLED.
  uint16_t year;
  uint8_t month, day, hour, minute, second, weekday;
  if (clock_.now(year, month, day, hour, minute, second, weekday)) {
    if (second != lastSecond) {
      lastSecond = second;
      display.showClock(clock_.weekdayString(), clock_.timeString(false),
                        clock_.dateString());
      digitalWrite(LED_PIN, second % 2 ? HIGH : LOW);
    }
  }

  delay(20);
}
