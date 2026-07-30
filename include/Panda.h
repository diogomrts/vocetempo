/*
 * Panda - draws a cute panda face using Adafruit_GFX primitives.
 *
 * This is the visual mascot for the (panda-themed) Vocetempo clock. It is
 * deliberately decoupled from any specific display: it draws onto any
 * Adafruit_GFX canvas, so the Display class can hand it the OLED without the
 * Panda code knowing what panel it is.
 *
 * The face is built from shapes (no stored bitmaps), so animation is just a
 * matter of changing the "pose" - the eyes, mouth and an optional waving paw
 * change while the silhouette stays put. That keeps it tiny and maintainable.
 *
 * On the monochrome OLED the panda reads as: a white silhouette (head + two
 * ear bumps) with the classic black eye patches, white eye dots, a black nose
 * and mouth.
 */

#ifndef VOCETEMPO_PANDA_H
#define VOCETEMPO_PANDA_H

#include <Arduino.h>

class Adafruit_GFX;  // forward declaration; only the .cpp needs the full type

class Panda {
 public:
  // The different expressions the panda can wear. The silhouette is identical
  // for all of them; only the facial features (and an optional paw) change.
  enum class Pose : uint8_t {
    Neutral,   // eyes open, calm
    Blink,     // eyes closed (used mid boot-splash and between other poses)
    Happy,     // upward-arc "smiling" eyes
    WaveLeft,  // happy, left paw raised
    WaveRight  // happy, right paw raised
  };

  // Draw a panda face centred at (cx, cy). `r` is the head radius in pixels;
  // every other feature is scaled from it so the panda can be any size. The
  // caller is responsible for clearing the buffer before and pushing it after.
  static void draw(Adafruit_GFX& g, int16_t cx, int16_t cy, int16_t r,
                   Pose pose);
};

#endif  // VOCETEMPO_PANDA_H
