#include "Display.h"

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

#include "Panda.h"

// Panel geometry for the Hailege 2.42" module.
static const uint8_t SCREEN_WIDTH = 128;
static const uint8_t SCREEN_HEIGHT = 64;

// I2C address confirmed by the scanner for this specific board.
static const uint8_t OLED_I2C_ADDRESS = 0x3C;

// This display has no dedicated reset pin wired, so pass -1.
static const int8_t OLED_RESET_PIN = -1;

// The underlying Adafruit driver instance. Kept file-local so the rest of the
// project only sees our Display class API.
static Adafruit_SSD1306 oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET_PIN);

// Forward declaration: draw a string horizontally centred at a text size/y.
// Defined lower down but used by several methods above it.
static void drawCentered(Adafruit_SSD1306& d, const String& text, uint8_t size,
                         int16_t y);

bool Display::begin() {
  // Wire.begin() with no args uses the ESP32 default I2C pins (SDA 21, SCL 22).
  Wire.begin();

  // A modest timeout means a stuck/glitching bus returns an error instead of
  // blocking the whole loop (which is what flooded the log during the fault).
  Wire.setTimeOut(50);  // ms

  // SSD1306_SWITCHCAPVCC tells the driver the panel generates its display
  // voltage internally (true for these modules).
  if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDRESS)) {
    _ready = false;
    return false;
  }

  _ready = true;
  oled.clearDisplay();
  oled.display();
  return true;
}

bool Display::recover() {
  // Tear the bus down and bring it back up, then re-init the panel. This
  // clears a wedged I2C peripheral after a wiring glitch.
  Wire.end();
  delay(20);
  Wire.begin();
  Wire.setTimeOut(50);
  delay(20);

  if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDRESS)) {
    _ready = false;
    return false;
  }
  _ready = true;
  oled.clearDisplay();
  oled.display();
  return true;
}

void Display::clear() {
  if (!_ready) return;
  oled.clearDisplay();
}

void Display::show() {
  if (!_ready) return;
  oled.display();
}

void Display::showTwoLines(const String& line1, const String& line2) {
  if (!_ready) return;

  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  // Line 1: larger text.
  oled.setTextSize(2);
  oled.setCursor(0, 12);
  oled.println(line1);

  // Line 2: smaller text.
  oled.setTextSize(1);
  oled.setCursor(0, 40);
  oled.println(line2);

  oled.display();
}

// Draw the panda on the left and the product name on the right. Shared by the
// boot splash frames so each frame only changes the pose.
static void drawSplashFrame(Adafruit_SSD1306& d, Panda::Pose pose) {
  d.clearDisplay();
  // Panda face on the left half.
  Panda::draw(d, 32, 32, 20, pose);
  // Wordmark on the right.
  d.setTextColor(SSD1306_WHITE);
  d.setTextSize(2);
  d.setCursor(64, 18);
  d.print(F("Voce"));
  d.setCursor(64, 36);
  d.print(F("tempo"));
  d.display();
}

void Display::showBootSplash() {
  if (!_ready) return;

  // A short scripted sequence of poses. Each entry is {pose, hold-ms}.
  struct Frame {
    Panda::Pose pose;
    uint16_t ms;
  };
  static const Frame frames[] = {
      {Panda::Pose::Neutral, 350}, {Panda::Pose::Blink, 120},
      {Panda::Pose::Neutral, 250}, {Panda::Pose::Happy, 300},
      {Panda::Pose::WaveRight, 350}, {Panda::Pose::WaveLeft, 350},
      {Panda::Pose::Happy, 400},
  };
  for (const Frame& f : frames) {
    drawSplashFrame(oled, f.pose);
    delay(f.ms);
  }
}

// Draw a small filled heart centred at (cx, cy). Two lobes + a triangle base.
static void drawHeart(Adafruit_SSD1306& d, int16_t cx, int16_t cy) {
  d.fillCircle(cx - 2, cy - 1, 2, SSD1306_WHITE);
  d.fillCircle(cx + 2, cy - 1, 2, SSD1306_WHITE);
  d.fillTriangle(cx - 4, cy, cx + 4, cy, cx, cy + 4, SSD1306_WHITE);
}

void Display::showPandaFrame(Panda::Pose pose, uint8_t hearts,
                             const String& caption) {
  if (!_ready) return;

  oled.clearDisplay();

  // The panda, big and centred (shifted up to leave room for the caption).
  Panda::draw(oled, 64, 28, 24, pose);

  // Hearts fill the empty columns to the LEFT and RIGHT of the panda (the
  // panda spans roughly x=40..88, so 0..36 and 92..128 are free). We lay out
  // two columns per side and four rows, and fill the slots alternating
  // left/right so the hearts grow outward symmetrically as petting increases.
  const int16_t leftX[2] = {10, 26};
  const int16_t rightX[2] = {102, 118};
  const int16_t rowY[4] = {8, 22, 36, 50};
  const uint8_t kMaxHearts = 16;  // 2 sides * 2 cols * 4 rows
  if (hearts > kMaxHearts) hearts = kMaxHearts;

  for (uint8_t i = 0; i < hearts; i++) {
    // Slot index within one side (0..7); alternate sides on each heart.
    uint8_t sideSlot = i / 2;      // 0,0,1,1,2,2,...
    bool right = (i % 2) == 1;     // even -> left, odd -> right
    uint8_t col = sideSlot % 2;    // 0 or 1
    uint8_t row = sideSlot / 2;    // 0..3
    int16_t x = right ? rightX[col] : leftX[col];
    drawHeart(oled, x, rowY[row]);
  }

  // Caption centred at the very bottom.
  if (caption.length()) {
    oled.setTextColor(SSD1306_WHITE);
    drawCentered(oled, caption, 1, 56);
  }

  oled.display();
}

// Helper: draw a string horizontally centred at a given text size and y.
static void drawCentered(Adafruit_SSD1306& d, const String& text,
                         uint8_t size, int16_t y) {
  d.setTextSize(size);
  int16_t x1, y1;
  uint16_t w, h;
  d.getTextBounds(text, 0, y, &x1, &y1, &w, &h);
  int16_t x = (SCREEN_WIDTH - (int16_t)w) / 2;
  if (x < 0) x = 0;
  d.setCursor(x, y);
  d.print(text);
}

// Draw a small crescent moon icon at (x,y) top-left, ~10px, to indicate quiet
// hours. Done by drawing a filled disc then cutting a second disc out of it.
static void drawMoon(Adafruit_SSD1306& d, int16_t x, int16_t y) {
  const int16_t r = 5;
  int16_t cx = x + r;
  int16_t cy = y + r;
  d.fillCircle(cx, cy, r, SSD1306_WHITE);
  // Cut a black disc offset to the left to form a crescent.
  d.fillCircle(cx - 3, cy, r, SSD1306_BLACK);
}

// Draw a small "muted speaker" icon (a speaker box + cone with a slash) at
// (x,y) top-left, ~10px tall, to indicate auto-announcements are muted.
static void drawMuteIcon(Adafruit_SSD1306& d, int16_t x, int16_t y) {
  // Speaker body: a small rectangle.
  d.fillRect(x, y + 3, 3, 4, SSD1306_WHITE);
  // Cone: a triangle flaring out to the right.
  d.fillTriangle(x + 3, y + 5, x + 7, y + 1, x + 7, y + 9, SSD1306_WHITE);
  // The "muted" slash across the whole icon.
  d.drawLine(x, y + 9, x + 9, y, SSD1306_WHITE);
}

void Display::showClock(const String& weekday, const String& time,
                        const String& date, bool quietHours, bool muted) {
  if (!_ready) return;

  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  // Weekday: small, top.
  drawCentered(oled, weekday, 1, 2);

  // Time: large, middle. Size 3 fits "HH:MM" nicely on 128px.
  drawCentered(oled, time, 3, 22);

  // Date: small, bottom.
  drawCentered(oled, date, 1, 54);

  // Quiet-hours moon icon, top-right corner.
  if (quietHours) {
    drawMoon(oled, SCREEN_WIDTH - 12, 1);
  }

  // Muted icon, top-left corner.
  if (muted) {
    drawMuteIcon(oled, 2, 1);
  }

  oled.display();
}

void Display::showMenu(const String& title, const String* items, uint8_t count,
                       uint8_t selected) {
  if (!_ready) return;

  oled.clearDisplay();
  oled.setTextSize(1);

  // Title bar: inverted row across the top.
  oled.fillRect(0, 0, SCREEN_WIDTH, 12, SSD1306_WHITE);
  oled.setTextColor(SSD1306_BLACK);
  oled.setCursor(2, 2);
  oled.print(title);
  oled.setTextColor(SSD1306_WHITE);

  // List area shows up to 4 rows of 13px each, windowed around the selection.
  const uint8_t kRows = 4;
  const uint8_t rowH = 13;
  uint8_t first = 0;
  if (count > kRows) {
    if (selected >= kRows - 1) first = selected - (kRows - 2);
    if (first + kRows > count) first = count - kRows;
  }

  for (uint8_t row = 0; row < kRows && (first + row) < count; row++) {
    uint8_t idx = first + row;
    int16_t y = 14 + row * rowH;
    if (idx == selected) {
      // Highlight the selected row.
      oled.fillRect(0, y - 1, SCREEN_WIDTH, rowH, SSD1306_WHITE);
      oled.setTextColor(SSD1306_BLACK);
    } else {
      oled.setTextColor(SSD1306_WHITE);
    }
    oled.setCursor(4, y + 1);
    oled.print(items[idx]);
  }

  oled.setTextColor(SSD1306_WHITE);
  oled.display();
}

void Display::showEditValue(const String& title, const String& value,
                            const String& hint) {
  if (!_ready) return;

  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  // Title at top.
  oled.setTextSize(1);
  oled.setCursor(2, 2);
  oled.print(title);

  // Value large in the middle, centred.
  drawCentered(oled, value, 2, 24);

  // Hint at the bottom (e.g. "UP/DOWN change  OK save").
  if (hint.length()) {
    oled.setTextSize(1);
    oled.setCursor(2, 54);
    oled.print(hint);
  }

  oled.display();
}
