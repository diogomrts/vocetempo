/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 2: Connect the OLED and display text.
 * -------------------------------------------------------------------------
 * Goal of this stage:
 *   Initialise the SSD1309 OLED over I2C and draw text on it, proving the
 *   display and our Display wrapper class work.
 *
 * Wiring (ESP32 <-> OLED, 4-pin I2C board):
 *   OLED GND -> ESP32 GND
 *   OLED VDD -> ESP32 3V3
 *   OLED SCL -> ESP32 GPIO 22
 *   OLED SDA -> ESP32 GPIO 21
 *
 * Expected behaviour:
 *   - Serial (115200) prints whether the display was found.
 *   - The OLED shows "Vocetempo" on the top line and a status line below.
 *   - The onboard LED still blinks as a "we're alive" heartbeat.
 */

#include <Arduino.h>

#include "Display.h"

static const uint8_t LED_PIN = 2;

// Our display wrapper (defined in Display.cpp / Display.h).
static Display display;

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - Stage 2: OLED display"));
  Serial.println(F("========================================"));

  if (display.begin()) {
    Serial.println(F("OLED initialised OK."));
    display.showTwoLines("Vocetempo", "Stage 2: display OK");
  } else {
    Serial.println(F("ERROR: OLED not found. Check wiring/address."));
  }
}

void loop() {
  // Heartbeat so we know the sketch is running even if the screen is blank.
  digitalWrite(LED_PIN, HIGH);
  delay(500);
  digitalWrite(LED_PIN, LOW);
  delay(500);
}
