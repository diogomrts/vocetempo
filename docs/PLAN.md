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
| Input     | KY-023 analog joystick                 | ADC+GPIO  | Deadzone, hysteresis, debounced         |
| Power     | 5V USB wall charger                    | USB-C     | Wall powered; no battery in v1         |

### Communication architecture

- OLED + DS3231 share the I2C bus.
- DFPlayer connects over UART.
- Speaker connects directly to the DFPlayer.
- Joystick: two axes on ADC1 (GPIO 32/33), press-switch on GPIO 25.

## Version 1 feature list

- Clock display: HH:MM (seconds optional later), date, weekday.
- Manual announcement: press a button, clock speaks the current time.
- Automatic announcements: Off / Hourly / Every 30 min / Every 15 min.
- Quiet hours: configurable start/end; auto announcements disabled, manual still works.
- Settings stored in ESP32 flash (Preferences/NVS): interval, quiet hours,
  volume, brightness, time, date, optional 12/24h mode, DST region.
- Automatic DST for a selectable region (off by default). Computed on-device
  from algorithmic rules, so it needs no network and no timezone database; see
  `include/Dst.h`. The RTC holds standard time and the offset is applied on
  read, so the hardware clock is never rewritten for a transition.
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

## Host unit tests

The hardware-free logic is unit-tested on the development machine with
`pio test -e native` (Unity, `test/`). Currently covered:

- `Dst` - daylight-saving rules and calendar maths, checked either side of every
  transition instant across several years and both hemispheres.
- `Announcer` - interval boundaries, quiet-hours windows, and the behaviour
  across DST transitions (a repeated hour must not silence the clock).
- `Joystick` - deadzone, hysteresis against ADC noise, and the dominant-axis
  latch that stops a diagonal push firing two actions at once.

This is the cheapest place to catch timing bugs, since neither class touches
I2C, UART or NVS. Prefer adding logic here over testing it only on hardware.

## Future (v2)

Battery operation, 18650 + USB charging, supercapacitor RTC backup, automatic
brightness, custom PCB, 3D-printed enclosure, larger speaker, multilingual
speech, voice selection, alarm, more DST regions.
