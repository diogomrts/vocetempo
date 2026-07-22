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

  // Clear the screen buffer (does not push to the panel until show()).
  void clear();

  // Push the current buffer to the physical panel.
  void show();

  // Convenience: draw two centred lines of text and push immediately.
  // Used for simple status/splash screens.
  void showTwoLines(const String& line1, const String& line2);

 private:
  bool _ready = false;
};

#endif  // VOCETEMPO_DISPLAY_H
