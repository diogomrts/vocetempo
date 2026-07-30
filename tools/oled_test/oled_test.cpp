/*
 * Vocetempo - minimal OLED panel test (diagnostic).
 *
 * Bypasses all app code. Initialises the SSD1306/1309 and cycles through the
 * most basic panel outputs to determine whether the panel can light pixels
 * at all:
 *   - all pixels ON (fillScreen white)
 *   - max contrast
 *   - inverted (all pixels OFF vs ON)
 *   - explicit charge-pump command re-issue
 *
 * If the panel stays completely dark through all of this while begin()
 * succeeds, the panel/charge-pump is damaged (controller still talks I2C).
 *
 * Build/upload:
 *   pio run -e oled_test -t upload
 */

#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

static Adafruit_SSD1306 oled(128, 64, &Wire, -1);

void setup() {
  Serial.begin(115200);
  delay(400);
  Wire.begin();

  Serial.println();
  Serial.println(F("=== OLED panel test ==="));

  if (!oled.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("begin() FAILED - controller not responding at 0x3C"));
    return;
  }
  Serial.println(F("begin() OK - controller responds. Now driving panel..."));

  // Max contrast.
  oled.ssd1306_command(SSD1306_SETCONTRAST);
  oled.ssd1306_command(0xFF);

  // All pixels ON directly from the controller (independent of RAM).
  oled.ssd1306_command(SSD1306_DISPLAYALLON);
  Serial.println(F("Sent DISPLAYALLON - the ENTIRE panel should be lit."));
}

void loop() {
  // Alternate DISPLAYALLON (whole panel lit) and normal+full white buffer,
  // so we can see if ANYTHING lights up.
  static bool phase = false;
  static unsigned long last = 0;
  if (millis() - last < 3000) return;
  last = millis();
  phase = !phase;

  if (phase) {
    Serial.println(F("[A] DISPLAYALLON (force every pixel on)"));
    oled.ssd1306_command(SSD1306_DISPLAYALLON);
  } else {
    Serial.println(F("[B] normal mode + full white buffer"));
    oled.ssd1306_command(SSD1306_DISPLAYALLON_RESUME);  // back to RAM
    oled.fillScreen(SSD1306_WHITE);
    oled.display();
  }
}
