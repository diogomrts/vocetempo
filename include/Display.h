/*
 * Display - thin wrapper around the OLED (SSD1309, 128x64, I2C).
 *
 * The SSD1309 controller is command-compatible with the SSD1306, so we drive
 * it with Adafruit's SSD1306 library.
 *
 * This class hides the library setup behind a small, project-specific API so
 * the rest of the code (clock UI, menus) never touches the display library
 * directly. That keeps things modular and easy to swap later.
 */

#ifndef VOCETEMPO_DISPLAY_H
#define VOCETEMPO_DISPLAY_H

#include <Arduino.h>

#include "Panda.h"

// Glyph shown beside a row on the controls/help screen. These describe the
// stick movement rather than a named button, so the help stays true to the
// hardware: an arrow the user can copy with their thumb.
enum class CtrlIcon : uint8_t {
  UpDown,      // up and down arrows stacked
  RightClick,  // right arrow plus a dot (push right, or press the stick)
  Left,        // left arrow
  LeftHold,    // left arrow plus a bar, meaning hold it rather than tap
};

// One line of the controls screen.
struct ControlRow {
  CtrlIcon icon;
  const char* text;
};

class Display {
 public:
  // Initialise the OLED over I2C. Returns false if the display was not found
  // on the bus (e.g. wiring problem). Safe to call once in setup().
  bool begin();

  // Attempt to recover the I2C bus + display after a fault (e.g. a wire
  // glitched). Re-inits Wire and re-runs the panel init. Returns true on
  // success. Safe to call repeatedly.
  bool recover();

  // Clear the screen buffer (does not push to the panel until show()).
  void clear();

  // Push the current buffer to the physical panel.
  void show();

  // Convenience: draw two centred lines of text and push immediately.
  // Used for simple status/splash screens.
  void showTwoLines(const String& line1, const String& line2);

  // Play the animated panda boot splash (blinks, waves, shows the name).
  // Blocking; runs for roughly a couple of seconds then returns. Called once
  // at startup before the clock face appears.
  void showBootSplash();

  // Render a single frame of the interactive "pet the panda" screen: a large
  // panda in the given pose, a caption at the bottom, and a row of hearts
  // showing how much it has been petted. Non-blocking (draws one frame); the
  // interaction loop lives in main.cpp so button handling stays in one place.
  void showPandaFrame(Panda::Pose pose, uint8_t hearts, const String& caption);

  // Draw the main clock face: weekday on top, large time in the middle,
  // date at the bottom. If quietHours is true, a small moon icon is shown in
  // the top-right corner; if muted is true, a speaker-with-slash icon is shown
  // in the top-left corner. Pushes to the panel immediately.
  void showClock(const String& weekday, const String& time,
                 const String& date, bool quietHours = false,
                 bool muted = false);

  // Draw a scrollable menu: a title bar plus a list of items with the
  // selected item highlighted. Shows a window of items around the selection.
  void showMenu(const String& title, const String* items, uint8_t count,
                uint8_t selected);

  // Draw a single value being edited: a title, the value large in the middle,
  // and up/down hints. Used for volume, interval, time fields, etc.
  void showEditValue(const String& title, const String& value,
                     const String& hint = "");

  // Draw the controls / help screen: a title bar plus one row per control,
  // each an icon showing the stick movement and a short label. Up to
  // kMaxControlRows fit on the panel.
  void showControls(const String& title, const ControlRow* rows, uint8_t count);
  static const uint8_t kMaxControlRows = 5;

 private:
  bool _ready = false;
};

#endif  // VOCETEMPO_DISPLAY_H
