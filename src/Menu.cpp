#include "Menu.h"

#include "Localization.h"

// The Str id for each main-menu row, in display order. The row order maps to
// handleMain()'s switch; the actual text is looked up per-language via tr().
static const Str kMainItemIds[] = {
    Str::Announce,    // 0
    Str::QuietStart,  // 1
    Str::QuietEnd,    // 2
    Str::Volume,      // 3
    Str::SetTime,     // 4
    Str::SetDate,     // 5
    Str::Dst,         // 6
    Str::Format,      // 7
    Str::Language,    // 8
    Str::Controls,    // 9
    Str::Exit,        // 10
};
static const uint8_t kMainCount = 11;

// Localized name for an announcement interval.
static const char* intervalName(AnnounceInterval iv, Language lang) {
  switch (iv) {
    case AnnounceInterval::Off: return tr(Str::IntervalOff, lang);
    case AnnounceInterval::Hourly: return tr(Str::IntervalHourly, lang);
    case AnnounceInterval::Half: return tr(Str::IntervalHalf, lang);
    case AnnounceInterval::Quarter: return tr(Str::IntervalQuarter, lang);
    default: return tr(Str::IntervalOff, lang);
  }
}

// Localized value shown on the summer-time screen. Region names are proper
// nouns and stay untranslated; only "Off" follows the UI language.
static const char* dstZoneLabel(DstZone zone, Language lang) {
  if (zone == DstZone::Off) return tr(Str::IntervalOff, lang);
  return dstZoneName(zone);
}

// Note: the date editor clamps the day with daysInMonth() from Dst.h rather
// than a local copy, so the leap-year rule lives in exactly one place (and is
// covered by the host unit tests).

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
  // Push settings into the live Announcer and clock, then persist.
  _announcer.setInterval(_settings.interval);
  _announcer.setQuietHours(_settings.quietEnabled, _settings.quietStartH,
                           _settings.quietStartM, _settings.quietEndH,
                           _settings.quietEndM);
  _clock.setDstZone(_settings.dstZone);
  _settings.save();
}

// ---- Rendering ----

void Menu::render() {
  if (!_active) return;
  char buf[24];
  Language lang = _settings.language;  // all labels follow the current language

  switch (_screen) {
    case Screen::Main: {
      String items[kMainCount];
      for (uint8_t i = 0; i < kMainCount; i++)
        items[i] = tr(kMainItemIds[i], lang);
      _display.showMenu(tr(Str::MenuTitle, lang), items, kMainCount, _mainSel);
      break;
    }
    case Screen::EditInterval:
      _display.showEditValue(tr(Str::Announce, lang),
                             intervalName(_settings.interval, lang),
                             tr(Str::HintSave, lang));
      break;
    case Screen::EditVolume:
      snprintf(buf, sizeof(buf), "%u", _settings.volume);
      _display.showEditValue(tr(Str::Volume, lang), buf, tr(Str::HintSave, lang));
      break;
    case Screen::EditFormat:
      _display.showEditValue(
          tr(Str::Format, lang),
          tr(_settings.use24h ? Str::Format24h : Str::Format12h, lang),
          tr(Str::HintSave, lang));
      break;
    case Screen::EditLanguage:
      // The language names stay in their own tongue (English/Portugues/Espanol)
      // so you can always recognise your language; the title is localized.
      _display.showEditValue(tr(Str::Language, lang),
                             languageName(_settings.language),
                             tr(Str::HintSave, lang));
      break;
    case Screen::EditDst:
      _display.showEditValue(tr(Str::Dst, lang),
                             dstZoneLabel(_settings.dstZone, lang),
                             tr(Str::HintSave, lang));
      break;
    case Screen::Controls: {
      // A read-only reference for the stick. Deliberately describes movements
      // rather than button names, so it stays correct regardless of how the
      // module ends up oriented in the enclosure.
      const ControlRow rows[] = {
          {CtrlIcon::UpDown, tr(Str::CtrlMove, lang)},
          {CtrlIcon::RightClick, tr(Str::CtrlSelect, lang)},
          {CtrlIcon::Left, tr(Str::CtrlBack, lang)},
          {CtrlIcon::Left, tr(Str::CtrlSpeak, lang)},
          {CtrlIcon::LeftHold, tr(Str::CtrlMute, lang)},
      };
      _display.showControls(tr(Str::Controls, lang), rows,
                            sizeof(rows) / sizeof(rows[0]));
      break;
    }
    case Screen::EditQuietStart:
    case Screen::EditQuietEnd: {
      snprintf(buf, sizeof(buf), "%02u:%02u", _editH, _editM);
      const char* title = tr(
          (_screen == Screen::EditQuietStart) ? Str::QuietStart : Str::QuietEnd,
          lang);
      const char* hint =
          tr((_editField == 0) ? Str::HintHour : Str::HintMin, lang);
      _display.showEditValue(title, buf, hint);
      break;
    }
    case Screen::EditTime: {
      snprintf(buf, sizeof(buf), "%02u:%02u", _editH, _editM);
      const char* hint =
          tr((_editField == 0) ? Str::HintHour : Str::HintMin, lang);
      _display.showEditValue(tr(Str::SetTime, lang), buf, hint);
      break;
    }
    case Screen::EditDate: {
      snprintf(buf, sizeof(buf), "%04u-%02u-%02u", _editYear, _editMonth, _editDay);
      const char* hint = tr(_editField == 0   ? Str::HintYear
                            : _editField == 1 ? Str::HintMon
                                              : Str::HintDay,
                            lang);
      _display.showEditValue(tr(Str::SetDate, lang), buf, hint);
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
    case Screen::EditLanguage: handleEditLanguage(b); break;
    case Screen::EditDst: handleEditDst(b); break;
    case Screen::Controls: handleControls(b); break;
  }
}

void Menu::handleControls(Buttons& b) {
  // Nothing to edit - any of confirm or back returns to the menu. Up/down are
  // ignored rather than scrolling, because every row already fits on screen.
  if (b.wasPressed(Button::Ok) || b.wasPressed(Button::Back)) {
    enterScreen(Screen::Main);
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
      case 6: enterScreen(Screen::EditDst); break;
      case 7: enterScreen(Screen::EditFormat); break;
      case 8: enterScreen(Screen::EditLanguage); break;
      case 9: enterScreen(Screen::Controls); break;
      case 10: _active = false; break;  // Exit
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

void Menu::handleEditLanguage(Buttons& b) {
  // Cycle English -> Portuguese -> Spanish.
  uint8_t v = static_cast<uint8_t>(_settings.language);
  if (b.wasPressed(Button::Up)) {
    v = (v + 1) % 3;
    _settings.language = static_cast<Language>(v);
    render();
  }
  if (b.wasPressed(Button::Down)) {
    v = (v == 0) ? 2 : v - 1;
    _settings.language = static_cast<Language>(v);
    render();
  }
  if (b.wasPressed(Button::Ok)) { applyAndSave(); enterScreen(Screen::Main); }
  if (b.wasPressed(Button::Back)) { _settings.load(); enterScreen(Screen::Main); }
}

void Menu::handleEditDst(Buttons& b) {
  // Cycle Off -> each supported region -> back to Off.
  const uint8_t n = static_cast<uint8_t>(DstZone::Count);
  uint8_t v = static_cast<uint8_t>(_settings.dstZone);
  if (b.wasPressed(Button::Up)) {
    v = (v + 1) % n;
    _settings.dstZone = static_cast<DstZone>(v);
    render();
  }
  if (b.wasPressed(Button::Down)) {
    v = (v == 0) ? n - 1 : v - 1;
    _settings.dstZone = static_cast<DstZone>(v);
    render();
  }
  if (b.wasPressed(Button::Ok)) {
    // Changing the region must NOT change what time the clock is showing.
    //
    // The RTC stores standard time, so a new region reinterprets the same
    // stored value - pick a summer region in August and a stored 16:35 would
    // start reading as 17:35. The time the user already set is the only ground
    // truth this device has (it has no network reference), so preserve it: read
    // the wall time under the old region, then write it straight back under the
    // new one, which re-derives the standard time to match.
    //
    // Net effect: selecting a region means "handle the changes from now on",
    // and the displayed time never moves until a real transition night.
    const DstZone oldZone = _clock.dstZone();
    if (_settings.dstZone != oldZone) {
      uint16_t yr; uint8_t mo, dy, hh, mm, ss, wd;
      bool haveTime = _clock.now(yr, mo, dy, hh, mm, ss, wd);
      applyAndSave();  // installs the new zone
      // Seconds are carried over, so re-homing the clock costs no accuracy.
      if (haveTime) _clock.setDateTime(yr, mo, dy, hh, mm, ss);
    } else {
      applyAndSave();
    }
    enterScreen(Screen::Main);
  }
  if (b.wasPressed(Button::Back)) {
    // Cancel: nothing was applied to the clock (only OK writes), so just drop
    // the edited value and reload the saved one.
    _settings.load();
    enterScreen(Screen::Main);
  }
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
