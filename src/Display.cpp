#include "Display.h"

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

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

bool Display::begin() {
  // Wire.begin() with no args uses the ESP32 default I2C pins (SDA 21, SCL 22).
  Wire.begin();

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
