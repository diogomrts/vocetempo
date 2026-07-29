#include "Menu.h"

// Labels for the main menu list. Order maps to onMainSelect().
static const char* kMainItems[] = {
    "Announce",   // 0
    "Quiet start",// 1
    "Quiet end",  // 2
    "Volume",     // 3
    "Set time",   // 4
    "Set date",   // 5
    "12/24 hour", // 6
    "Exit",       // 7
};
static const uint8_t kMainCount = 8;

static const char* intervalName(AnnounceInterval iv) {
  switch (iv) {
    case AnnounceInterval::Off: return "Off";
    case AnnounceInterval::Hourly: return "Hourly";
    case AnnounceInterval::Half: return "30 min";
    case AnnounceInterval::Quarter: return "15 min";
    default: return "Off";
  }
}

static uint8_t daysInMonth(uint16_t y, uint8_t m) {
  static const uint8_t d[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  if (m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) return 29;
  if (m < 1 || m > 12) return 31;
  return d[m - 1];
}

void Menu::open() {
  _active = true;
  _screen = Screen::Main;
  _mainSel = 0;
  render();
}

void Menu::enterScreen(Screen s) {
  _screen = s;
  _editField = 0;

  // Seed edit scratch values from current state.
  uint16_t yr; uint8_t mo, dy, hh, mm, ss, wd;
  bool haveTime = _clock.now(yr, mo, dy, hh, mm, ss, wd);

  switch (s) {
    case Screen::EditQuietStart:
      _editH = _settings.quietStartH; _editM = _settings.quietStartM; break;
    case Screen::EditQuietEnd:
      _editH = _settings.quietEndH; _editM = _settings.quietEndM; break;
    case Screen::EditTime:
      if (haveTime) { _editH = hh; _editM = mm; } break;
    case Screen::EditDate:
      if (haveTime) { _editYear = yr; _editMonth = mo; _editDay = dy; } break;
    default: break;
  }
  render();
}

void Menu::applyAndSave() {
  // Push settings into the live Announcer, then persist.
  _announcer.setInterval(_settings.interval);
  _announcer.setQuietHours(_settings.quietEnabled, _settings.quietStartH,
                           _settings.quietStartM, _settings.quietEndH,
                           _settings.quietEndM);
  _settings.save();
}

// ---- Rendering ----

void Menu::render() {
  if (!_active) return;
  char buf[24];

  switch (_screen) {
    case Screen::Main: {
      String items[kMainCount];
      for (uint8_t i = 0; i < kMainCount; i++) items[i] = kMainItems[i];
      _display.showMenu("Settings", items, kMainCount, _mainSel);
      break;
    }
    case Screen::EditInterval:
      _display.showEditValue("Announce", intervalName(_settings.interval),
                             "UP/DN  OK save");
      break;
    case Screen::EditVolume:
      snprintf(buf, sizeof(buf), "%u", _settings.volume);
      _display.showEditValue("Volume", buf, "UP/DN  OK save");
      break;
    case Screen::EditFormat:
      _display.showEditValue("Format", _settings.use24h ? "24 hour" : "12 hour",
                             "UP/DN  OK save");
      break;
    case Screen::EditQuietStart:
    case Screen::EditQuietEnd: {
      snprintf(buf, sizeof(buf), "%02u:%02u", _editH, _editM);
      const char* title =
          (_screen == Screen::EditQuietStart) ? "Quiet start" : "Quiet end";
      const char* hint = (_editField == 0) ? "UP/DN hour OK>" : "UP/DN min OK save";
      _display.showEditValue(title, buf, hint);
      break;
    }
    case Screen::EditTime: {
      snprintf(buf, sizeof(buf), "%02u:%02u", _editH, _editM);
      const char* hint = (_editField == 0) ? "UP/DN hour OK>" : "UP/DN min OK save";
      _display.showEditValue("Set time", buf, hint);
      break;
    }
    case Screen::EditDate: {
      snprintf(buf, sizeof(buf), "%04u-%02u-%02u", _editYear, _editMonth, _editDay);
      const char* hint = _editField == 0 ? "UP/DN year OK>"
                        : _editField == 1 ? "UP/DN mon OK>"
                                          : "UP/DN day OK save";
      _display.showEditValue("Set date", buf, hint);
      break;
    }
  }
}

// ---- Input handling ----

void Menu::handle(Buttons& b) {
  if (!_active) return;
  switch (_screen) {
    case Screen::Main: handleMain(b); break;
    case Screen::EditInterval: handleEditInterval(b); break;
    case Screen::EditVolume: handleEditVolume(b); break;
    case Screen::EditFormat: handleEditFormat(b); break;
    case Screen::EditQuietStart: handleEditQuiet(b, true); break;
    case Screen::EditQuietEnd: handleEditQuiet(b, false); break;
    case Screen::EditTime: handleEditTime(b); break;
    case Screen::EditDate: handleEditDate(b); break;
  }
}

void Menu::handleMain(Buttons& b) {
  if (b.repeat(Button::Up)) {
    _mainSel = (_mainSel == 0) ? kMainCount - 1 : _mainSel - 1;
    render();
  }
  if (b.repeat(Button::Down)) {
    _mainSel = (_mainSel + 1) % kMainCount;
    render();
  }
  if (b.wasPressed(Button::Back)) {
    _active = false;  // exit to clock
  }
  if (b.wasPressed(Button::Ok)) {
    switch (_mainSel) {
      case 0: enterScreen(Screen::EditInterval); break;
      case 1: enterScreen(Screen::EditQuietStart); break;
      case 2: enterScreen(Screen::EditQuietEnd); break;
      case 3: enterScreen(Screen::EditVolume); break;
      case 4: enterScreen(Screen::EditTime); break;
      case 5: enterScreen(Screen::EditDate); break;
      case 6: enterScreen(Screen::EditFormat); break;
      case 7: _active = false; break;  // Exit
    }
  }
}

void Menu::handleEditInterval(Buttons& b) {
  // Cycle Off -> Hourly -> Half -> Quarter.
  uint8_t v = static_cast<uint8_t>(_settings.interval);
  if (b.wasPressed(Button::Up)) {
    v = (v + 1) % 4;
    _settings.interval = static_cast<AnnounceInterval>(v);
    render();
  }
  if (b.wasPressed(Button::Down)) {
    v = (v == 0) ? 3 : v - 1;
    _settings.interval = static_cast<AnnounceInterval>(v);
    render();
  }
  if (b.wasPressed(Button::Ok)) { applyAndSave(); enterScreen(Screen::Main); }
  if (b.wasPressed(Button::Back)) { _settings.load(); enterScreen(Screen::Main); }
}

void Menu::handleEditVolume(Buttons& b) {
  if (b.repeat(Button::Up) && _settings.volume < 30) {
    _settings.volume++; render();
  }
  if (b.repeat(Button::Down) && _settings.volume > 0) {
    _settings.volume--; render();
  }
  if (b.wasPressed(Button::Ok)) { applyAndSave(); enterScreen(Screen::Main); }
  if (b.wasPressed(Button::Back)) { _settings.load(); enterScreen(Screen::Main); }
}

void Menu::handleEditFormat(Buttons& b) {
  if (b.wasPressed(Button::Up) || b.wasPressed(Button::Down)) {
    _settings.use24h = !_settings.use24h; render();
  }
  if (b.wasPressed(Button::Ok)) { applyAndSave(); enterScreen(Screen::Main); }
  if (b.wasPressed(Button::Back)) { _settings.load(); enterScreen(Screen::Main); }
}

void Menu::handleEditQuiet(Buttons& b, bool isStart) {
  if (b.repeat(Button::Up)) {
    if (_editField == 0) _editH = (_editH + 1) % 24;
    else _editM = (_editM + 1) % 60;
    render();
  }
  if (b.repeat(Button::Down)) {
    if (_editField == 0) _editH = (_editH == 0) ? 23 : _editH - 1;
    else _editM = (_editM == 0) ? 59 : _editM - 1;
    render();
  }
  if (b.wasPressed(Button::Ok)) {
    if (_editField == 0) { _editField = 1; render(); }
    else {
      if (isStart) { _settings.quietStartH = _editH; _settings.quietStartM = _editM; }
      else { _settings.quietEndH = _editH; _settings.quietEndM = _editM; }
      _settings.quietEnabled = true;
      applyAndSave();
      enterScreen(Screen::Main);
    }
  }
  if (b.wasPressed(Button::Back)) { enterScreen(Screen::Main); }
}

void Menu::handleEditTime(Buttons& b) {
  if (b.repeat(Button::Up)) {
    if (_editField == 0) _editH = (_editH + 1) % 24;
    else _editM = (_editM + 1) % 60;
    render();
  }
  if (b.repeat(Button::Down)) {
    if (_editField == 0) _editH = (_editH == 0) ? 23 : _editH - 1;
    else _editM = (_editM == 0) ? 59 : _editM - 1;
    render();
  }
  if (b.wasPressed(Button::Ok)) {
    if (_editField == 0) { _editField = 1; render(); }
    else {
      // Write to RTC, keeping the existing date. Seconds reset to 0.
      uint16_t yr; uint8_t mo, dy, hh, mm, ss, wd;
      _clock.now(yr, mo, dy, hh, mm, ss, wd);
      _clock.setDateTime(yr, mo, dy, _editH, _editM, 0);
      enterScreen(Screen::Main);
    }
  }
  if (b.wasPressed(Button::Back)) { enterScreen(Screen::Main); }
}

void Menu::handleEditDate(Buttons& b) {
  if (b.repeat(Button::Up)) {
    if (_editField == 0) _editYear++;
    else if (_editField == 1) _editMonth = (_editMonth % 12) + 1;
    else _editDay = (_editDay % daysInMonth(_editYear, _editMonth)) + 1;
    render();
  }
  if (b.repeat(Button::Down)) {
    if (_editField == 0) { if (_editYear > 2020) _editYear--; }
    else if (_editField == 1) _editMonth = (_editMonth == 1) ? 12 : _editMonth - 1;
    else _editDay = (_editDay <= 1) ? daysInMonth(_editYear, _editMonth) : _editDay - 1;
    render();
  }
  if (b.wasPressed(Button::Ok)) {
    if (_editField < 2) { _editField++; render(); }
    else {
      // Clamp day to the month, keep current time.
      uint8_t maxd = daysInMonth(_editYear, _editMonth);
      if (_editDay > maxd) _editDay = maxd;
      uint16_t yr; uint8_t mo, dy, hh, mm, ss, wd;
      _clock.now(yr, mo, dy, hh, mm, ss, wd);
      _clock.setDateTime(_editYear, _editMonth, _editDay, hh, mm, ss);
      enterScreen(Screen::Main);
    }
  }
  if (b.wasPressed(Button::Back)) { enterScreen(Screen::Main); }
}
