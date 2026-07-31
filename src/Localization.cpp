#include "Localization.h"

// One row per Str id, columns are [English, Portuguese, Spanish]. Kept in the
// exact order of the Str enum so we can index directly. On-screen text is
// ASCII-only on purpose (see the note in Strings.h).
static const char* const kTable[static_cast<uint8_t>(Str::Count)][3] = {
    //  English         Portuguese        Spanish
    {"Muted",          "Silenciado",     "Silenciado"},   // Muted
    {"Sound on",       "Som ligado",     "Sonido on"},    // SoundOn

    {"Settings",       "Definicoes",     "Ajustes"},      // MenuTitle
    {"Announce",       "Anunciar",       "Anunciar"},     // Announce
    {"Quiet start",    "Silencio ini",   "Silencio ini"}, // QuietStart
    {"Quiet end",      "Silencio fim",   "Silencio fin"}, // QuietEnd
    {"Volume",         "Volume",         "Volumen"},      // Volume
    {"Set time",       "Acertar hora",   "Ajustar hora"}, // SetTime
    {"Set date",       "Acertar data",   "Ajustar fecha"},// SetDate
    {"Format",         "Formato",        "Formato"},      // Format
    {"Language",       "Idioma",         "Idioma"},       // Language
    {"Exit",           "Sair",           "Salir"},        // Exit

    {"Off",            "Desligado",      "Apagado"},      // IntervalOff
    {"Hourly",         "A cada hora",    "Cada hora"},    // IntervalHourly
    {"30 min",         "30 min",         "30 min"},       // IntervalHalf
    {"15 min",         "15 min",         "15 min"},       // IntervalQuarter

    {"24 hour",        "24 horas",       "24 horas"},     // Format24h
    {"12 hour",        "12 horas",       "12 horas"},     // Format12h

    {"UP/DN  OK save", "CIMA/BX OK grav","ARR/AB OK guar"},// HintSave
    {"UP/DN hour OK>", "CIMA/BX hora OK>","ARR/AB hora OK>"},// HintHour
    {"UP/DN min OK save","CIMA/BX min grav","ARR/AB min guar"},// HintMin
    {"UP/DN year OK>", "CIMA/BX ano OK>","ARR/AB ano OK>"},// HintYear
    {"UP/DN mon OK>",  "CIMA/BX mes OK>","ARR/AB mes OK>"},// HintMon
    {"UP/DN day OK save","CIMA/BX dia grav","ARR/AB dia guar"},// HintDay
};

const char* tr(Str id, Language lang) {
  uint8_t row = static_cast<uint8_t>(id);
  if (row >= static_cast<uint8_t>(Str::Count)) return "";
  uint8_t col = static_cast<uint8_t>(lang);
  if (col > 2) col = 0;  // defensive: fall back to English
  return kTable[row][col];
}

// Weekday names, [lang][dow] with dow 0=Sunday..6=Saturday. ASCII-only.
static const char* const kWeekdays[3][7] = {
    // English
    {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
     "Saturday"},
    // Portuguese (accent-free for the GFX font)
    {"Domingo", "Segunda", "Terca", "Quarta", "Quinta", "Sexta", "Sabado"},
    // Spanish (accent-free)
    {"Domingo", "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado"},
};

const char* weekdayName(uint8_t dow, Language lang) {
  if (dow > 6) return "---";
  uint8_t col = static_cast<uint8_t>(lang);
  if (col > 2) col = 0;
  return kWeekdays[col][dow];
}
