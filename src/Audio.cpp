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
  if (volume > 30) volume = 30;
  _volume = volume;  // remember it even if the module isn't ready yet
  if (!_ready) return;
  dfplayer.volume(volume);
}

void Audio::playIndex(uint16_t index) {
  if (!_ready) return;
  // playMp3Folder plays /mp3/000<index>.mp3 regardless of copy order.
  dfplayer.playMp3Folder(index);
}

void Audio::playIndexBlocking(uint16_t index, unsigned long timeoutMs) {
  if (!_ready) return;

  // Drain any stale status messages so they don't get mistaken for THIS
  // clip's "finished" event.
  while (dfplayer.available()) {
    dfplayer.readType();
    dfplayer.read();
  }

  // Re-assert the configured volume right before playing. Clone modules often
  // ignore a volume command issued too soon after their power-on reset and
  // revert to full volume; re-sending it here guarantees the user's setting is
  // always honoured.
  dfplayer.volume(_volume);
  delay(20);  // give the clone a moment to apply it before the play command

  dfplayer.playMp3Folder(index);

  // Wait until the module reports this track finished, or we time out.
  // A short minimum play time avoids misreading the initial start transient
  // as an immediate finish.
  unsigned long start = millis();
  delay(40);  // let playback actually begin

  while (millis() - start < timeoutMs) {
    // Allow the UI to abort speech (e.g. a button press).
    if (_interruptCheck && _interruptCheck()) {
      stop();
      return;
    }
    if (dfplayer.available()) {
      uint8_t type = dfplayer.readType();
      dfplayer.read();
      if (type == DFPlayerPlayFinished) {
        return;  // move straight to the next word for natural flow
      }
    }
    delay(2);
  }
  // Timed out - continue anyway so a phrase never hangs indefinitely.
}

void Audio::stop() {
  if (!_ready) return;
  dfplayer.stop();
}

void Audio::speakTime(uint8_t hour24, uint8_t minute, bool use24h,
                      uint16_t langOffset) {
  if (!_ready) return;
  (void)use24h;  // v1 uses the 12-hour pre-rendered phrase sets

  // Each time-of-day is a single pre-rendered phrase file, offset by language:
  //   index = langOffset + hour24 * 60 + minute + 1
  //   (English 0, Portuguese 2000, Spanish 4000 - see generate_multilang.py)
  // Playing one file = gapless, naturally intonated speech.
  uint16_t index = langOffset + (uint16_t)hour24 * 60 + minute + 1;
  playIndexBlocking(index, 6000);
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
    case DFPlayerFeedBack:
      // Routine command ACK (we run with isACK=true, so every command gets
      // one). Silently ignored: logging it made a normal announcement print
      // "status type 11 value 3958", which reads like a fault in a soak log
      // when nothing is wrong at all.
      break;
    default:
      Serial.print(F("[DFPlayer] status type "));
      Serial.print(type);
      Serial.print(F(" value "));
      Serial.println(value);
      break;
  }
}
