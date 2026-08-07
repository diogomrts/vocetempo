#include "Joystick.h"

// Absolute value on a signed deflection, kept local so this file needs no
// standard library at all.
static inline int32_t absDelta(int32_t v) { return v < 0 ? -v : v; }

void Joystick::setCentre(uint16_t centreX, uint16_t centreY) {
  _centreX = centreX;
  _centreY = centreY;
}

void Joystick::setInvert(bool invertX, bool invertY) {
  _invertX = invertX;
  _invertY = invertY;
}

bool Joystick::centreIsPlausible(uint16_t rawX, uint16_t rawY) {
  const int32_t dx = static_cast<int32_t>(rawX) - kAdcCentreNominal;
  const int32_t dy = static_cast<int32_t>(rawY) - kAdcCentreNominal;
  return absDelta(dx) <= kCentreTolerance && absDelta(dy) <= kCentreTolerance;
}

JoyDir Joystick::update(uint16_t rawX, uint16_t rawY) {
  int32_t dx = static_cast<int32_t>(rawX) - static_cast<int32_t>(_centreX);
  int32_t dy = static_cast<int32_t>(rawY) - static_cast<int32_t>(_centreY);
  if (_invertX) dx = -dx;
  if (_invertY) dy = -dy;

  const int32_t ax = absDelta(dx);
  const int32_t ay = absDelta(dy);

  if (_active != JoyDir::None) {
    // A direction is already engaged. Only the axis it belongs to is consulted,
    // so drifting sideways mid-push cannot silently switch to another action.
    const bool onX = (_active == JoyDir::Left || _active == JoyDir::Right);
    const int32_t delta = onX ? dx : dy;
    const int32_t magnitude = onX ? ax : ay;

    if (magnitude >= kRelease) {
      // Still held. Track the sign so sliding from one end of the axis to the
      // other without letting go registers as the new direction rather than
      // staying stuck on the old one.
      if (onX) {
        _active = (delta < 0) ? JoyDir::Left : JoyDir::Right;
      } else {
        _active = (delta < 0) ? JoyDir::Up : JoyDir::Down;
      }
      return _active;
    }
    // Fell back inside the release threshold: let go and re-acquire below, so
    // moving straight from one axis to the other still works in one motion.
    _active = JoyDir::None;
  }

  // Nothing engaged: require a deliberate push on at least one axis.
  if (ax < kEngage && ay < kEngage) return JoyDir::None;

  // Whichever axis is pushed further wins. Ties go to the vertical axis, which
  // carries menu scrolling and is by far the most used.
  if (ay >= ax) {
    _active = (dy < 0) ? JoyDir::Up : JoyDir::Down;
  } else {
    _active = (dx < 0) ? JoyDir::Left : JoyDir::Right;
  }
  return _active;
}
