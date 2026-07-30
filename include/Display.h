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

  // Draw the main clock face: weekday on top, large time in the middle,
  // date at the bottom. If quietHours is true, a small moon icon is shown in
  // the top-right corner. Pushes to the panel immediately.
  void showClock(const String& weekday, const String& time,
                 const String& date, bool quietHours = false);

  // Draw a scrollable menu: a title bar plus a list of items with the
  // selected item highlighted. Shows a window of items around the selection.
  void showMenu(const String& title, const String* items, uint8_t count,
                uint8_t selected);

  // Draw a single value being edited: a title, the value large in the middle,
  // and up/down hints. Used for volume, interval, time fields, etc.
  void showEditValue(const String& title, const String& value,
                     const String& hint = "");

 private:
  bool _ready = false;
};

#endif  // VOCETEMPO_DISPLAY_H
