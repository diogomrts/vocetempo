# Vocetempo - Development Plan

A standalone talking bedside clock built on an ESP32. Works fully offline: no
Wi-Fi, Bluetooth, internet, or phone required.

## Philosophy

1. Simplicity
2. Reliability
3. Easy maintenance
4. Easy future expansion

Build a working breadboard prototype first. Only design a PCB/enclosure once
all features work.

## Hardware

| Part      | Component                              | Interface | Notes                                  |
| --------- | -------------------------------------- | --------- | -------------------------------------- |
| MCU       | DollaTek ESP32 (ESP-WROOM-32, CP2102)  | USB-C     | Main controller                        |
| Display   | Hailege 2.42" SSD1309 128x64           | I2C       | Clock, menus, icons                    |
| RTC       | DollaTek DS3231 + AT24C32              | I2C       | Accurate timekeeping; no battery yet   |
| Audio     | DFPlayer Mini                          | UART      | Plays speech clips from its own microSD|
| Speaker   | CQRobot 3W 4ohm                        | analog    | Wired directly to DFPlayer             |
| Storage   | microSDHC 32GB (FAT32)                 | -         | Used only by DFPlayer                  |
| Buttons   | 4x push (UP / DOWN / OK / BACK)        | GPIO      | Debounced                              |
| Power     | 5V USB wall charger                    | USB-C     | Wall powered; no battery in v1         |

### Communication architecture

- OLED + DS3231 share the I2C bus.
- DFPlayer connects over UART.
- Speaker connects directly to the DFPlayer.
- Buttons are GPIO inputs.

## Version 1 feature list

- Clock display: HH:MM (seconds optional later), date, weekday.
- Manual announcement: press a button, clock speaks the current time.
- Automatic announcements: Off / Hourly / Every 30 min / Every 15 min.
- Quiet hours: configurable start/end; auto announcements disabled, manual still works.
- Settings stored in ESP32 flash (Preferences/NVS): interval, quiet hours,
  volume, brightness, time, date, optional 12/24h mode.
- Display brightness (future): day/night with automatic switching.

## Audio design

Use modular audio clips ("It is", "Fourteen", "Thirty", "PM"), played in
sequence. Avoids one MP3 per time and makes multi-language support easy later.

## Suggested libraries

- Display: Adafruit_GFX + Adafruit_SSD1306 (SSD1309 compatible)
- RTC: RTClib
- Audio: DFRobotDFPlayerMini
- Buttons: Bounce2 (debouncing)
- Settings: ESP32 Preferences

## Development stages

1. Verify ESP32 programming. Display "Hello". **<- current**
2. Connect OLED. Display text.
3. Connect RTC. Read + display time.
4. Set RTC manually. Verify persistence while powered.
5. Connect DFPlayer. Play one test audio.
6. Connect speaker. Verify volume.
7. Read buttons.
8. Manual speech: press button, speak time.
9. Automatic announcements.
10. Quiet hours.
11. Settings menu + storage.
12. Long runtime testing (stability, RTC accuracy, timing).

For each stage: explain wiring, explain the code, verify behaviour, then continue.

## Future (v2)

Battery operation, 18650 + USB charging, supercapacitor RTC backup, automatic
brightness, custom PCB, 3D-printed enclosure, larger speaker, multilingual
speech, voice selection, alarm, DST support.
