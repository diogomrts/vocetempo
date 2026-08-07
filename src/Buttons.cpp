#include "Buttons.h"

// ---- Pins (see docs/WIRING.md) ----------------------------------------------
//
// The axes MUST be on ADC1 channels. ADC2 is unusable while Wi-Fi is active and
// is generally less well behaved on the ESP32; ADC1 is GPIO 32-39. GPIO 32/33
// are the two pins the UP/DOWN buttons used, so the joystick drops onto the
// existing wiring with nothing else to move.
//
// The switch needs an internal pull-up, which GPIO 34-39 do not have (they are
// input-only), so it goes on GPIO 25 - the pin the OK button used.
static const uint8_t kPinAxisX = 32;  // KY-023 VRx (ADC1_CH4)
static const uint8_t kPinAxisY = 33;  // KY-023 VRy (ADC1_CH5)
static const uint8_t kPinSwitch = 25;  // KY-023 SW, shorts to GND when pressed

// Axis orientation. Which way a pot swings depends on how the module ends up
// mounted, so these are the one thing to flip after assembly if the stick feels
// backwards. Confirm with `pio run -e joystick_test -t upload`, which prints the
// raw values and the decoded direction.
static const bool kInvertX = false;
static const bool kInvertY = false;

// Number of resting samples averaged at boot to find the stick's centre.
static const uint8_t kCalibrationSamples = 8;

// Simple, dependency-free debounce shared by every logical action. For each one
// we track the last stable state, the last raw reading, and when it last
// changed. The analog axes already have hysteresis, so this mostly matters for
// the mechanical switch - but running everything through one path keeps press
// edges and hold-to-repeat behaving identically whichever input produced them.
static const unsigned long kDebounceMs = 8;

static bool stablePressed[4];   // debounced "is pressed"
static bool lastRawPressed[4];  // previous raw reading
static unsigned long lastChange[4];
static bool pressedEdge[4];     // set on a fresh press, cleared by wasPressed()
static unsigned long pressStart[4];  // when the current press began
static unsigned long lastRepeat[4];  // last time repeat() fired for a hold

// Map the decoded stick direction plus the switch onto the four logical
// actions. OK deliberately has two sources: a right push and a press.
static void mapToActions(JoyDir dir, bool switchPressed, bool out[4]) {
  out[static_cast<uint8_t>(Button::Up)] = (dir == JoyDir::Up);
  out[static_cast<uint8_t>(Button::Down)] = (dir == JoyDir::Down);
  out[static_cast<uint8_t>(Button::Ok)] = (dir == JoyDir::Right) || switchPressed;
  out[static_cast<uint8_t>(Button::Back)] = (dir == JoyDir::Left);
}

void Buttons::begin() {
  pinMode(kPinSwitch, INPUT_PULLUP);
  // The axes are analog inputs; no pull-up, or it would fight the pot divider.
  pinMode(kPinAxisX, INPUT);
  pinMode(kPinAxisY, INPUT);

  _joystick.setInvert(kInvertX, kInvertY);

  // Calibrate the deadzone against where this particular stick actually rests,
  // rather than assuming a perfect midpoint.
  uint32_t sumX = 0, sumY = 0;
  for (uint8_t i = 0; i < kCalibrationSamples; i++) {
    sumX += analogRead(kPinAxisX);
    sumY += analogRead(kPinAxisY);
    delay(2);
  }
  const uint16_t avgX = sumX / kCalibrationSamples;
  const uint16_t avgY = sumY / kCalibrationSamples;

  // Only trust the sample if it looks like a centred stick. If the user happens
  // to be holding it at boot - or an axis is unplugged and reading a rail -
  // baking that in would bias the deadzone for the whole session and could leave
  // a direction permanently engaged.
  _calibrated = Joystick::centreIsPlausible(avgX, avgY);
  if (_calibrated) {
    _joystick.setCentre(avgX, avgY);
  }
  _rawX = avgX;
  _rawY = avgY;

  // Seed the debounce state from the current reading so a stick held at boot
  // does not register as a fresh press on the first update().
  bool raw[4];
  mapToActions(_joystick.update(avgX, avgY), digitalRead(kPinSwitch) == LOW, raw);
  for (uint8_t i = 0; i < kCount; i++) {
    stablePressed[i] = raw[i];
    lastRawPressed[i] = raw[i];
    lastChange[i] = millis();
    pressedEdge[i] = false;
  }
}

void Buttons::update() {
  const unsigned long now = millis();

  // One read per axis per call. The hysteresis in Joystick makes averaging
  // unnecessary, and update() runs from inside audio playback too, so keeping it
  // cheap matters.
  _rawX = analogRead(kPinAxisX);
  _rawY = analogRead(kPinAxisY);
  const JoyDir dir = _joystick.update(_rawX, _rawY);
  const bool switchPressed = (digitalRead(kPinSwitch) == LOW);

  bool raw[4];
  mapToActions(dir, switchPressed, raw);

  for (uint8_t i = 0; i < kCount; i++) {
    if (raw[i] != lastRawPressed[i]) {
      // Raw reading changed - restart the debounce timer.
      lastRawPressed[i] = raw[i];
      lastChange[i] = now;
    } else if (now - lastChange[i] >= kDebounceMs) {
      // Reading has been stable long enough - accept it.
      if (raw[i] != stablePressed[i]) {
        stablePressed[i] = raw[i];
        if (raw[i]) {
          // Transitioned to pressed: record a press edge.
          pressedEdge[i] = true;
          pressStart[i] = now;
          lastRepeat[i] = now;
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

bool Buttons::repeat(Button b, unsigned long firstDelayMs,
                     unsigned long intervalMs) {
  uint8_t i = static_cast<uint8_t>(b);
  if (i >= kCount) return false;

  // Fire immediately on the initial press edge.
  if (pressedEdge[i]) {
    pressedEdge[i] = false;
    lastRepeat[i] = millis();
    return true;
  }

  // While held, fire repeatedly after the initial delay.
  if (stablePressed[i]) {
    unsigned long now = millis();
    if (now - pressStart[i] >= firstDelayMs &&
        now - lastRepeat[i] >= intervalMs) {
      lastRepeat[i] = now;
      return true;
    }
  }
  return false;
}

bool Buttons::isDown(Button b) {
  uint8_t i = static_cast<uint8_t>(b);
  if (i >= kCount) return false;
  return stablePressed[i];
}
