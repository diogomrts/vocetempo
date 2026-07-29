/*
 * Vocetempo - raw button/GPIO diagnostic (not part of the app).
 *
 * Prints the live logic level of the four button GPIOs continuously. Use it
 * to isolate a wiring problem from the button itself:
 *
 *   - With nothing pressed and INPUT_PULLUP enabled, every pin should read 1
 *     (HIGH).
 *   - Touch a jumper from a pin directly to GND (bypassing the button) and
 *     that pin should read 0 (LOW). If it does, the ESP32 pin + pull-up are
 *     fine and the problem is the button/its wiring.
 *   - If a pin never changes when you short it to GND, that pin/wire is the
 *     problem.
 *
 * Build/upload just this tool:
 *   pio run -e button_test -t upload
 *   pio device monitor -b 115200
 */

#include <Arduino.h>

static const uint8_t PINS[] = {32, 33, 25, 26};
static const char* NAMES[] = {"UP(32)", "DOWN(33)", "OK(25)", "BACK(26)"};
static const uint8_t N = 4;

void setup() {
  Serial.begin(115200);
  delay(300);
  for (uint8_t i = 0; i < N; i++) pinMode(PINS[i], INPUT_PULLUP);

  Serial.println();
  Serial.println(F("Vocetempo raw button test"));
  Serial.println(F("All should read 1 when idle; 0 when that pin touches GND."));
}

void loop() {
  Serial.print(F("levels: "));
  for (uint8_t i = 0; i < N; i++) {
    Serial.print(NAMES[i]);
    Serial.print('=');
    Serial.print(digitalRead(PINS[i]));
    Serial.print("  ");
  }
  Serial.println();
  delay(250);
}
