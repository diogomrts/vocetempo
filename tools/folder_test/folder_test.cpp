/*
 * Vocetempo - DFPlayer folder-addressing test (diagnostic, not the app).
 *
 * Verifies whether this DFPlayer clone supports playLargeFolder(folder, file),
 * which we need for multi-language support (one numbered folder per language,
 * up to ~3000 files each).
 *
 * Card layout for this test:
 *   /01/001.mp3   (any audible clip)
 *
 * It tries several addressing methods in turn so we can see which one works:
 *   1. playLargeFolder(1, 1)   -> folder 01, file 001  (what we want)
 *   2. playFolder(1, 1)        -> older folder command (max 255 files)
 *   3. playMp3Folder(1)        -> /mp3/0001.mp3 (known-good baseline)
 *
 * Watch the serial log and LISTEN: note which method produces sound.
 *
 * Build/upload:
 *   pio run -e folder_test -t upload
 */

#include <Arduino.h>
#include <DFRobotDFPlayerMini.h>

static const int PIN_RX = 14;  // ESP32 <- DFPlayer TX
static const int PIN_TX = 27;  // ESP32 -> DFPlayer RX

static HardwareSerial dfSerial(2);
static DFRobotDFPlayerMini dfplayer;

void setup() {
  Serial.begin(115200);
  delay(400);
  dfSerial.begin(9600, SERIAL_8N1, PIN_RX, PIN_TX);
  delay(200);

  Serial.println();
  Serial.println(F("=== DFPlayer folder-addressing test ==="));

  if (!dfplayer.begin(dfSerial, true, true)) {
    Serial.println(F("ERROR: DFPlayer not responding."));
    return;
  }
  Serial.println(F("DFPlayer OK."));
  dfplayer.volume(18);
  delay(300);

  Serial.println(F("[1] playLargeFolder(1,1) -> /01/001.mp3"));
  dfplayer.playLargeFolder(1, 1);
}

void loop() {
  // Only test playLargeFolder now, with a DISTINCT clip in /01/001.mp3
  // ("large folder one"). If you hear those words, folder addressing works.
  static unsigned long last = 0;
  if (millis() - last < 5000) return;
  last = millis();
  Serial.println(F("playMp3Folder(4001) -> /mp3/4001.mp3 (expect 'index four thousand one')"));
  dfplayer.playMp3Folder(4001);
}
