/*
 * Menu - the settings user interface state machine.
 *
 * Driven by the four buttons. Renders through Display, edits a Settings struct
 * (and the RTC for time/date), and saves to NVS when the user leaves an edit.
 *
 * Structure:
 *   Main list -> select an item with OK -> edit screen -> OK saves, BACK
 *   cancels. BACK on the main list exits the menu back to the clock.
 */

#ifndef VOCETEMPO_MENU_H
#define VOCETEMPO_MENU_H

#include <Arduino.h>

#include "Announcer.h"
#include "Buttons.h"
#include "Display.h"
#include "RealtimeClock.h"
#include "Settings.h"

class Menu {
 public:
  Menu(Display& display, Settings& settings, Announcer& announcer,
       RealtimeClock& clock)
      : _display(display),
        _settings(settings),
        _announcer(announcer),
        _clock(clock) {}

  // Enter the menu (from the clock screen).
  void open();

  // True while the menu is active (main loop shows menu instead of clock).
  bool isActive() const { return _active; }

  // Handle one set of button events for this frame. Call every loop while
  // active. Returns false when the menu has just exited (back to clock).
  void handle(Buttons& buttons);

  // Redraw the current menu screen.
  void render();

 private:
  enum class Screen : uint8_t {
    Main,
    EditInterval,
    EditQuietStart,
    EditQuietEnd,
    EditVolume,
    EditTime,
    EditDate,
    EditFormat,
    EditLanguage,
  };

  Display& _display;
  Settings& _settings;
  Announcer& _announcer;
  RealtimeClock& _clock;

  bool _active = false;
  Screen _screen = Screen::Main;
  uint8_t _mainSel = 0;

  // Scratch fields used while editing time/date/quiet hours.
  uint8_t _editH = 0, _editM = 0;
  uint16_t _editYear = 2026;
  uint8_t _editMonth = 1, _editDay = 1;
  uint8_t _editField = 0;  // which sub-field is being changed

  void enterScreen(Screen s);
  void applyAndSave();

  void handleMain(Buttons& b);
  void handleEditInterval(Buttons& b);
  void handleEditVolume(Buttons& b);
  void handleEditFormat(Buttons& b);
  void handleEditQuiet(Buttons& b, bool isStart);
  void handleEditTime(Buttons& b);
  void handleEditDate(Buttons& b);
  void handleEditLanguage(Buttons& b);
};

#endif  // VOCETEMPO_MENU_H
