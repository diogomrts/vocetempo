/*
 * Vocetempo - KY-023 joystick diagnostic (not part of the app).
 *
 * Prints the live raw ADC value of both axes, the switch level, and the
 * direction the shared decoder makes of them. Use it to confirm the wiring and,
 * more importantly, to work out the ORIENTATION before trusting the real UI.
 *
 * What to expect:
 *
 *   - Hands off the stick, both axes should sit near 1900-2100 and dir=None.
 *     A reading pinned at 0 or 4095 means that axis is not connected (or is
 *     wired to the wrong pin).
 *   - sw=1 idle, sw=0 while you push the stick down like a button. If sw never
 *     changes, the SW pin is not connected.
 *   - Push the stick the way you want "UP" to mean and check it prints dir=Up.
 *     If it prints Down, set kInvertY = true in src/Buttons.cpp. Likewise if
 *     left/right are swapped, set kInvertX = true.
 *   - If pushing up prints Left or Right, the two axis wires are swapped:
 *     exchange VRx and VRy.
 *
 * The engage/release thresholds printed at startup come from Joystick.h, so if
 * the stick feels too eager or too stiff, tune them there and they change
 * everywhere at once.
 *
 * Build/upload just this tool:
 *   pio run -e joystick_test -t upload
 *   pio device monitor -b 115200
 */

#include <Arduino.h>

#include "Joystick.h"

// Must match src/Buttons.cpp.
static const uint8_t PIN_X = 32;
static const uint8_t PIN_Y = 33;
static const uint8_t PIN_SW = 25;

static Joystick joystick;

static const char* dirName(JoyDir d) {
  switch (d) {
    case JoyDir::Up: return "Up   ";
    case JoyDir::Down: return "Down ";
    case JoyDir::Left: return "Left ";
    case JoyDir::Right: return "Right";
    case JoyDir::None:
    default: return "None ";
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);

  pinMode(PIN_SW, INPUT_PULLUP);
  pinMode(PIN_X, INPUT);
  pinMode(PIN_Y, INPUT);

  Serial.println();
  Serial.println(F("Vocetempo KY-023 joystick test"));
  Serial.print(F("Pins: VRx=GPIO"));
  Serial.print(PIN_X);
  Serial.print(F("  VRy=GPIO"));
  Serial.print(PIN_Y);
  Serial.print(F("  SW=GPIO"));
  Serial.println(PIN_SW);
  Serial.print(F("Thresholds: engage="));
  Serial.print(Joystick::kEngage);
  Serial.print(F("  release="));
  Serial.println(Joystick::kRelease);

  // Same calibration the real firmware does, so the numbers here match it.
  uint32_t sx = 0, sy = 0;
  for (uint8_t i = 0; i < 8; i++) {
    sx += analogRead(PIN_X);
    sy += analogRead(PIN_Y);
    delay(2);
  }
  const uint16_t cx = sx / 8, cy = sy / 8;
  const bool ok = Joystick::centreIsPlausible(cx, cy);
  if (ok) joystick.setCentre(cx, cy);

  Serial.print(F("Measured centre: x="));
  Serial.print(cx);
  Serial.print(F(" y="));
  Serial.print(cy);
  Serial.println(ok ? F("  (accepted)")
                    : F("  (REJECTED - stick held, or an axis not connected;"
                        " using nominal 2048)"));
  Serial.println(F("Hands off = None. Push each way and check the direction."));
}

void loop() {
  const uint16_t x = analogRead(PIN_X);
  const uint16_t y = analogRead(PIN_Y);
  const JoyDir dir = joystick.update(x, y);

  Serial.print(F("x="));
  Serial.print(x);
  Serial.print(F("\ty="));
  Serial.print(y);
  Serial.print(F("\tsw="));
  Serial.print(digitalRead(PIN_SW));
  Serial.print(F("\tdir="));
  Serial.print(dirName(dir));
  // Deflection from the calibrated centre, which is what the thresholds act on.
  Serial.print(F("\tdx="));
  Serial.print((int)x - (int)joystick.centreX());
  Serial.print(F("\tdy="));
  Serial.println((int)y - (int)joystick.centreY());

  delay(150);
}
