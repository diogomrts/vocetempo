/*
 * Buttons - debounced reading of the four front-panel push buttons.
 *
 * Each button connects its GPIO to GND when pressed. We use the ESP32's
 * internal pull-ups (INPUT_PULLUP), so a press reads LOW (active-low). The
 * Bounce2 library filters mechanical contact bounce.
 *
 * Wiring (see docs/WIRING.md), each button's other leg to the GND rail:
 *   UP   -> GPIO 32
 *   DOWN -> GPIO 33
 *   OK   -> GPIO 25
 *   BACK -> GPIO 26
 */

#ifndef VOCETEMPO_BUTTONS_H
#define VOCETEMPO_BUTTONS_H

#include <Arduino.h>

// Logical button identifiers.
enum class Button : uint8_t { Up, Down, Ok, Back, Count };

class Buttons {
 public:
  // Configure the GPIOs with pull-ups and set up debouncing.
  void begin();

  // Call once per loop() to sample all buttons. Must run frequently.
  void update();

  // True on the single update() where the button transitioned to pressed
  // (i.e. a fresh press edge). Good for menu navigation / triggers.
  bool wasPressed(Button b);

  // Hold-to-repeat: returns true once on the initial press, then repeatedly
  // while the button stays held (after firstDelayMs, every intervalMs). Ideal
  // for incrementing values like volume or time fields.
  bool repeat(Button b, unsigned long firstDelayMs = 400,
              unsigned long intervalMs = 120);

  // True while the button is currently held down.
  bool isDown(Button b);

 private:
  static const uint8_t kCount = static_cast<uint8_t>(Button::Count);
};

#endif  // VOCETEMPO_BUTTONS_H
