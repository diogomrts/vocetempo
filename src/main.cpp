/*
 * Vocetempo - a standalone talking bedside clock.
 *
 * -------------------------------------------------------------------------
 * STAGE 1: Verify ESP32 programming.
 * -------------------------------------------------------------------------
 * Goal of this stage:
 *   Prove that we can compile, upload, and run code on the ESP32, and that
 *   we can see output over the USB serial connection.
 *
 * There is no display, RTC, audio, or buttons wired up yet. This is purely
 * a "hello world" heartbeat so we know the toolchain and board work before
 * we add any hardware.
 *
 * Expected behaviour:
 *   - The onboard LED (GPIO 2 on most ESP32 dev boards) blinks once a second.
 *   - The serial monitor (115200 baud) prints a startup banner, then prints
 *     an incrementing "Hello from Vocetempo" message every second.
 */

#include <Arduino.h>

// Most ESP32 dev boards route the onboard blue LED to GPIO 2.
// If your DollaTek board's LED is on a different pin, adjust this.
static const uint8_t LED_PIN = 2;

// Counts how many seconds we've been running, for the serial heartbeat.
static unsigned long tickCount = 0;

void setup() {
  // Start the USB serial connection. This must match monitor_speed in
  // platformio.ini (115200).
  Serial.begin(115200);

  // Give the serial connection a brief moment to come up so we don't miss
  // the first messages after a reset.
  delay(500);

  pinMode(LED_PIN, OUTPUT);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - talking bedside clock"));
  Serial.println(F("  Stage 1: ESP32 programming check"));
  Serial.println(F("========================================"));
  Serial.println(F("If you can read this, the toolchain works!"));
  Serial.println();
}

void loop() {
  // Blink: LED on for half a second, off for half a second.
  digitalWrite(LED_PIN, HIGH);
  delay(500);
  digitalWrite(LED_PIN, LOW);
  delay(500);

  // Print a heartbeat once per full on/off cycle (~1 second).
  tickCount++;
  Serial.print(F("Hello from Vocetempo - tick "));
  Serial.println(tickCount);
}
