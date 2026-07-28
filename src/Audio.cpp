#include "Audio.h"

#include <DFRobotDFPlayerMini.h>

// UART pins for the DFPlayer. The 30-pin ESP32 DevKit lacks GPIO16/17, so we
// use free pins and route UART2 to them (the ESP32 pin matrix allows this).
static const int PIN_DFPLAYER_RX = 14;  // ESP32 receives  <- DFPlayer TX
static const int PIN_DFPLAYER_TX = 27;  // ESP32 transmits -> DFPlayer RX (via 1k)

// Use hardware UART2 for the DFPlayer link.
static HardwareSerial dfSerial(2);
static DFRobotDFPlayerMini dfplayer;

bool Audio::begin() {
  // 9600 baud is the DFPlayer's fixed protocol speed.
  dfSerial.begin(9600, SERIAL_8N1, PIN_DFPLAYER_RX, PIN_DFPLAYER_TX);

  // The module needs a moment after power-up before it answers.
  delay(200);

  // Second arg: isACK=true (wait for acknowledgements), third: doReset=true.
  if (!dfplayer.begin(dfSerial, /*isACK=*/true, /*doReset=*/true)) {
    _ready = false;
    return false;
  }

  _ready = true;
  return true;
}

void Audio::setVolume(uint8_t volume) {
  if (!_ready) return;
  if (volume > 30) volume = 30;
  dfplayer.volume(volume);
}

void Audio::playIndex(uint16_t index) {
  if (!_ready) return;
  // playMp3Folder plays /mp3/000<index>.mp3 regardless of copy order.
  dfplayer.playMp3Folder(index);
}

bool Audio::isBusy() {
  if (!_ready) return false;
  // available() is true when the module has a status message (e.g. finished).
  return dfplayer.available();
}

void Audio::pollStatus() {
  if (!_ready) return;
  if (!dfplayer.available()) return;

  uint8_t type = dfplayer.readType();
  int value = dfplayer.read();

  switch (type) {
    case DFPlayerPlayFinished:
      Serial.print(F("[DFPlayer] finished track "));
      Serial.println(value);
      break;
    case DFPlayerError:
      Serial.print(F("[DFPlayer] error code "));
      Serial.println(value);
      break;
    case DFPlayerCardInserted:
      Serial.println(F("[DFPlayer] SD card inserted"));
      break;
    case DFPlayerCardOnline:
      Serial.println(F("[DFPlayer] SD card online"));
      break;
    case DFPlayerCardRemoved:
      Serial.println(F("[DFPlayer] SD card removed"));
      break;
    default:
      Serial.print(F("[DFPlayer] status type "));
      Serial.print(type);
      Serial.print(F(" value "));
      Serial.println(value);
      break;
  }
}
