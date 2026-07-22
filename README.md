# Vocetempo

A standalone **talking bedside clock** built on an ESP32. It works completely
offline — no Wi-Fi, Bluetooth, internet, or phone required. It shows the time
on an OLED and speaks it aloud, automatically at configurable intervals or
on demand with a button.

> The name blends Italian _voce_ (voice) with _tempo_ (time), rooted in the
> Latin _vox_ + _tempus_.

## Features (v1)

- Large clock display (HH:MM), date, and weekday on a 2.42" OLED.
- Spoken time on demand (button) and automatically (hourly / 30 min / 15 min).
- Quiet hours: silence automatic announcements overnight (manual still works).
- Fully on-device configuration; settings persist in flash.
- Modular speech clips for compact storage and easy future languages.

## Hardware

- DollaTek ESP32 dev board (ESP-WROOM-32, CP2102, USB-C)
- Hailege 2.42" SSD1309 128x64 OLED (I2C)
- DollaTek DS3231 RTC (I2C)
- DFPlayer Mini + microSDHC (audio)
- CQRobot 3W 4ohm speaker
- 4 push buttons (UP / DOWN / OK / BACK)
- 5V USB wall power

See [`docs/PLAN.md`](docs/PLAN.md) for the full hardware map, wiring, and the
staged development roadmap.

## Toolchain

- [PlatformIO](https://platformio.org/) with the Arduino framework for ESP32.
- Board environment: `esp32dev`.

## Build & upload

```sh
# Build
pio run

# Upload to the connected board
pio run --target upload

# Open the serial monitor (115200 baud)
pio device monitor
```

## Status

**Stage 1 of 12** — verifying ESP32 programming with a serial "Hello"
heartbeat and onboard LED blink. Hardware peripherals are added one stage at a
time; see the roadmap in `docs/PLAN.md`.

## License

MIT — see [`LICENSE`](LICENSE).
