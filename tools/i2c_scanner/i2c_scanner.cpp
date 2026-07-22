/*
 * Vocetempo - I2C bus scanner (diagnostic tool, not part of the app).
 *
 * -------------------------------------------------------------------------
 * STAGE 2 (part 1): Confirm the ESP32 can see the OLED over I2C.
 * -------------------------------------------------------------------------
 * This sketch probes every possible 7-bit I2C address (0x01..0x7E) and
 * reports which ones respond. Run this BEFORE trying to draw anything on
 * the display: if the scanner doesn't find your OLED, the problem is
 * wiring/power, not code.
 *
 * Wiring (ESP32 <-> OLED, 4-pin I2C board):
 *   OLED GND -> ESP32 GND
 *   OLED VCC -> ESP32 3V3   (use 3.3V, not 5V)
 *   OLED SCL -> ESP32 GPIO 22
 *   OLED SDA -> ESP32 GPIO 21
 *
 * Expected result:
 *   Your board is labeled 0x7A (8-bit), which is 7-bit address 0x3D.
 *   So you should see: "I2C device found at address 0x3D".
 *
 * Build/upload just this tool:
 *   pio run -e i2c_scanner -t upload
 *   pio device monitor -b 115200
 */

#include <Arduino.h>
#include <Wire.h>

// Scan a bus on the given SDA/SCL pins and report devices found.
static uint8_t scanBus(int sda, int scl) {
  Wire.begin(sda, scl);
  delay(50);

  Serial.print(F("--- Scanning with SDA=GPIO "));
  Serial.print(sda);
  Serial.print(F(", SCL=GPIO "));
  Serial.print(scl);
  Serial.println(F(" ---"));

  uint8_t devicesFound = 0;
  for (uint8_t address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    uint8_t error = Wire.endTransmission();

    if (error == 0) {
      Serial.print(F("  I2C device found at address 0x"));
      if (address < 16) Serial.print('0');
      Serial.print(address, HEX);

      if (address == 0x3D || address == 0x3C) {
        Serial.print(F("  <- likely the OLED display"));
      } else if (address == 0x68) {
        Serial.print(F("  <- likely the DS3231 RTC"));
      } else if (address == 0x57) {
        Serial.print(F("  <- likely the AT24C32 EEPROM (on the RTC board)"));
      }
      Serial.println();
      devicesFound++;
    }
  }

  if (devicesFound == 0) {
    Serial.println(F("  (nothing found on this pin pair)"));
  }
  return devicesFound;
}

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println(F("========================================"));
  Serial.println(F("  Vocetempo - I2C scanner (dual-pin)"));
  Serial.println(F("========================================"));
}

void loop() {
  Serial.println(F("Scanning both pin orientations..."));
  Serial.println();

  // Normal orientation.
  uint8_t a = scanBus(21, 22);
  Serial.println();

  // Swapped orientation.
  uint8_t b = scanBus(22, 21);
  Serial.println();

  if (a == 0 && b == 0) {
    Serial.println(F("RESULT: No devices on EITHER orientation."));
    Serial.println(F("Likely a solder joint (SDA or SCL) open, or a bad wire."));
  } else if (a > 0) {
    Serial.println(F("RESULT: Found on NORMAL wiring (SDA=21, SCL=22). Correct!"));
  } else {
    Serial.println(F("RESULT: Found ONLY when SWAPPED (SDA=22, SCL=21)."));
    Serial.println(F("=> Your SDA and SCL wires are reversed. Swap them."));
  }

  Serial.println(F("--- rescanning in 5s ---"));
  Serial.println();
  delay(5000);
}
