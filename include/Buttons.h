/*
 * Buttons - the UI input layer: turns physical input into four logical actions.
 *
 * The rest of the firmware only ever asks for UP / DOWN / OK / BACK, so the
 * hardware behind them can change without touching Menu or main. As of v1 that
 * hardware is a single KY-023 analog thumbstick rather than four push buttons.
 *
 * Mapping (see docs/WIRING.md for pins):
 *   stick up       -> UP
 *   stick down     -> DOWN
 *   stick right    -> OK     (so you can confirm without pushing down)
 *   press the stick-> OK
 *   stick left     -> BACK   (tap speaks the time, hold mutes, exits menus)
 *
 * The axis maths - deadzone, hysteresis and the dominant-axis latch that stops
 * a diagonal push firing two actions - lives in Joystick.h. This class adds the
 * parts that are the same for any input device: debouncing, one-shot press
 * edges, and hold-to-repeat.
 *
 * Note the switch is wired to GND and read with an internal pull-up, so a press
 * reads LOW (active-low), the same as the push buttons it replaces.
 */

#ifndef VOCETEMPO_BUTTONS_H
#define VOCETEMPO_BUTTONS_H

#include <Arduino.h>

#include "Joystick.h"

// Logical UI actions. Named after the buttons they replaced, because that is
// what they mean to the user interface.
enum class Button : uint8_t { Up, Down, Ok, Back, Count };

class Buttons {
 public:
  // Configure the GPIOs, sample the stick's resting position to calibrate the
  // deadzone, and initialise debouncing.
  void begin();

  // Call once per loop() to sample the stick and switch. Must run frequently.
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

  // Raw diagnostics, for the boot log and tools/joystick_test. Not used by the
  // UI, which should always go through the logical actions above.
  uint16_t rawX() const { return _rawX; }
  uint16_t rawY() const { return _rawY; }
  JoyDir direction() const { return _joystick.direction(); }
  bool calibrated() const { return _calibrated; }
  uint16_t centreX() const { return _joystick.centreX(); }
  uint16_t centreY() const { return _joystick.centreY(); }

 private:
  static const uint8_t kCount = static_cast<uint8_t>(Button::Count);

  Joystick _joystick;
  uint16_t _rawX = 0;
  uint16_t _rawY = 0;
  bool _calibrated = false;
};

#endif  // VOCETEMPO_BUTTONS_H
