#include "Panda.h"

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>  // for the SSD1306_WHITE / SSD1306_BLACK colours

// The panda is drawn in two colours only: WHITE (lit pixel) and BLACK (off).
// We reuse the SSD1306 colour constants so the look matches the rest of the UI.
static const uint16_t W = SSD1306_WHITE;
static const uint16_t B = SSD1306_BLACK;

// Draw a filled ellipse. Adafruit_GFX has fillCircle but not fillEllipse on
// all versions, so we roll a tiny one via horizontal scan-lines. rx/ry are the
// horizontal/vertical radii.
static void fillEllipse(Adafruit_GFX& g, int16_t cx, int16_t cy, int16_t rx,
                        int16_t ry, uint16_t colour) {
  if (rx <= 0 || ry <= 0) return;
  for (int16_t dy = -ry; dy <= ry; dy++) {
    // Half-width of the ellipse at this row: rx * sqrt(1 - (dy/ry)^2).
    float t = 1.0f - (float)(dy * dy) / (float)(ry * ry);
    if (t < 0) t = 0;
    int16_t dx = (int16_t)(rx * sqrtf(t) + 0.5f);
    g.drawFastHLine(cx - dx, cy + dy, 2 * dx + 1, colour);
  }
}

// Draw one eye. The panda's signature is a large black patch with a small
// white eye inside. When `open` is false we draw a closed/blinking eye (a
// short white arc) instead of the white dot, keeping the black patch.
static void drawEye(Adafruit_GFX& g, int16_t ex, int16_t ey, int16_t patchRx,
                    int16_t patchRy, bool open, bool happy) {
  // The black patch sits on the white face. It is slightly tilted-oval shaped
  // which is what makes a panda look like a panda.
  fillEllipse(g, ex, ey, patchRx, patchRy, B);

  if (happy) {
    // A happy "^_^" eye: a small upward arc drawn in white inside the patch.
    for (int16_t dx = -2; dx <= 2; dx++) {
      int16_t yy = ey + (int16_t)(abs(dx)) - 1;  // shallow V -> looks like ^
      g.drawPixel(ex + dx, yy, W);
      g.drawPixel(ex + dx, yy - 1, W);
    }
  } else if (open) {
    // Open eye: a white dot (the eyeball) with a black pupil for sparkle.
    fillEllipse(g, ex, ey, 2, 2, W);
    g.drawPixel(ex, ey, B);
  } else {
    // Closed/blink: a short horizontal white line across the patch.
    g.drawFastHLine(ex - 2, ey, 5, W);
  }
}

// Draw a raised paw (a small white disc with a black outline) at (px,py).
static void drawPaw(Adafruit_GFX& g, int16_t px, int16_t py, int16_t r) {
  g.fillCircle(px, py, r, W);
  g.drawCircle(px, py, r, B);
}

void Panda::draw(Adafruit_GFX& g, int16_t cx, int16_t cy, int16_t r,
                 Panda::Pose pose) {
  // --- Ears: two black discs behind the head, poking out the top corners. ---
  int16_t earR = (int16_t)(r * 0.45f);
  int16_t earDX = (int16_t)(r * 0.75f);
  int16_t earDY = (int16_t)(r * 0.70f);
  g.fillCircle(cx - earDX, cy - earDY, earR, W);
  g.fillCircle(cx + earDX, cy - earDY, earR, W);
  // Inner black of the ears.
  g.fillCircle(cx - earDX, cy - earDY, earR - 2, B);
  g.fillCircle(cx + earDX, cy - earDY, earR - 2, B);

  // --- Head: a big white disc. ---
  g.fillCircle(cx, cy, r, W);

  // --- Eyes: the black patches + eyeballs. Placed symmetrically. ---
  int16_t eyeDX = (int16_t)(r * 0.42f);
  int16_t eyeDY = (int16_t)(r * 0.12f);
  int16_t patchRx = (int16_t)(r * 0.28f);
  int16_t patchRy = (int16_t)(r * 0.34f);

  bool open = (pose != Pose::Blink);
  bool happy = (pose == Pose::Happy || pose == Pose::WaveLeft ||
                pose == Pose::WaveRight);
  drawEye(g, cx - eyeDX, cy - eyeDY, patchRx, patchRy, open, happy);
  drawEye(g, cx + eyeDX, cy - eyeDY, patchRx, patchRy, open, happy);

  // --- Nose: a small black triangle-ish blob below and between the eyes. ---
  int16_t noseY = cy + (int16_t)(r * 0.30f);
  fillEllipse(g, cx, noseY, 3, 2, B);

  // --- Mouth: a little black arc under the nose. Happy = wider smile. ---
  int16_t mouthY = noseY + 3;
  if (happy) {
    // Wider "w"-ish smile made from two small arcs.
    g.drawPixel(cx, mouthY + 2, B);
    for (int16_t dx = 1; dx <= 4; dx++) {
      int16_t yy = mouthY + 2 - (int16_t)(dx >= 3 ? 1 : 0);
      g.drawPixel(cx - dx, yy, B);
      g.drawPixel(cx + dx, yy, B);
    }
  } else {
    // Neutral: a short vertical line down from the nose then a tiny smile.
    g.drawFastVLine(cx, mouthY, 2, B);
    g.drawPixel(cx - 1, mouthY + 2, B);
    g.drawPixel(cx + 1, mouthY + 2, B);
  }

  // --- Optional waving paw. ---
  int16_t pawR = (int16_t)(r * 0.22f);
  if (pose == Pose::WaveRight) {
    drawPaw(g, cx + r + pawR, cy - r + pawR, pawR);
  } else if (pose == Pose::WaveLeft) {
    drawPaw(g, cx - r - pawR, cy - r + pawR, pawR);
  }
}
