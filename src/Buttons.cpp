#include "Buttons.h"

// GPIO for each button, indexed by the Button enum order (Up, Down, Ok, Back).
static const uint8_t kPins[] = {32, 33, 25, 26};

// Simple, dependency-free debounce. For each button we track the last stable
// state, the last raw reading, and when it last changed. This avoids relying
// on a third-party library and is easy to reason about / maintain.
static const unsigned long kDebounceMs = 20;

static bool stableLow[4];       // debounced "is pressed" (active-low -> LOW)
static bool lastRawLow[4];      // previous raw reading
static unsigned long lastChange[4];
static bool pressedEdge[4];     // set true on a fresh press, cleared by wasPressed()

void Buttons::begin() {
  for (uint8_t i = 0; i < kCount; i++) {
    pinMode(kPins[i], INPUT_PULLUP);
    bool low = (digitalRead(kPins[i]) == LOW);
    stableLow[i] = low;
    lastRawLow[i] = low;
    lastChange[i] = millis();
    pressedEdge[i] = false;
  }
}

void Buttons::update() {
  unsigned long now = millis();
  for (uint8_t i = 0; i < kCount; i++) {
    bool rawLow = (digitalRead(kPins[i]) == LOW);

    if (rawLow != lastRawLow[i]) {
      // Raw reading changed - restart the debounce timer.
      lastRawLow[i] = rawLow;
      lastChange[i] = now;
    } else if (now - lastChange[i] >= kDebounceMs) {
      // Reading has been stable long enough - accept it.
      if (rawLow != stableLow[i]) {
        stableLow[i] = rawLow;
        if (rawLow) {
          // Transitioned to pressed (HIGH->LOW): record a press edge.
          pressedEdge[i] = true;
        }
      }
    }
  }
}

bool Buttons::wasPressed(Button b) {
  uint8_t i = static_cast<uint8_t>(b);
  if (i >= kCount) return false;
  if (pressedEdge[i]) {
    pressedEdge[i] = false;  // consume the edge
    return true;
  }
  return false;
}

bool Buttons::isDown(Button b) {
  uint8_t i = static_cast<uint8_t>(b);
  if (i >= kCount) return false;
  return stableLow[i];
}
