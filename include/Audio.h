/*
 * Audio - thin wrapper around the DFPlayer Mini (UART).
 *
 * Hides DFRobotDFPlayerMini behind a small project API. The DFPlayer plays
 * MP3 clips stored on its own microSD card; the ESP32 just sends commands
 * over a serial (UART) link.
 *
 * Wiring (30-pin ESP32 DevKit; it lacks GPIO16/17 so we use 27/14):
 *   ESP32 GPIO 27 -> DFPlayer RX (through a 1k resistor)
 *   ESP32 GPIO 14 <- DFPlayer TX
 *   DFPlayer VCC  -> 5V, GND -> shared ground
 *   Speaker across SPK_1 / SPK_2.
 *
 * Files on the card live in /mp3 named 0001.mp3, 0002.mp3, ... and are
 * addressed by their numeric index.
 */

#ifndef VOCETEMPO_AUDIO_H
#define VOCETEMPO_AUDIO_H

#include <Arduino.h>

class Audio {
 public:
  // Initialise the UART link and the DFPlayer. Returns false if the module
  // does not respond (check wiring, power, and that a card is inserted).
  bool begin();

  // Set playback volume, 0..30.
  void setVolume(uint8_t volume);

  // Play /mp3/000<index>.mp3 by its numeric index (1 = 0001.mp3).
  void playIndex(uint16_t index);

  // Optional interrupt check: if set, it is polled during blocking playback;
  // when it returns true, playback is stopped early. Lets the UI stay
  // responsive (e.g. a button press aborts speech).
  typedef bool (*InterruptCheck)();
  void setInterruptCheck(InterruptCheck cb) { _interruptCheck = cb; }

  // Play a clip and block until it finishes (or a timeout). Used to chain
  // several clips into one spoken phrase. Aborts early if the interrupt
  // check returns true.
  void playIndexBlocking(uint16_t index, unsigned long timeoutMs = 4000);

  // Stop any current playback immediately.
  void stop();

  // Speak the given time as a sequence of clips, e.g. "It is ten forty five PM".
  //   hour24  : 0..23
  //   minute  : 0..59
  //   use24h  : true = 24-hour speech, false = 12-hour with AM/PM
  void speakTime(uint8_t hour24, uint8_t minute, bool use24h);

  // True while a clip is actively playing (uses the BUSY state if available).
  bool isBusy();

  // Poll for and print any DFPlayer status/error messages to Serial. Call
  // periodically from loop() during bring-up to see what the module reports.
  void pollStatus();

 private:
  bool _ready = false;
  InterruptCheck _interruptCheck = nullptr;
};

#endif  // VOCETEMPO_AUDIO_H
