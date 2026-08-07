# Vocetempo

A standalone **talking bedside clock** built on an ESP32. It works completely
offline — no Wi-Fi, Bluetooth, internet, or phone required. It shows the time
on an OLED and speaks it aloud, automatically at configurable intervals or
on demand with a button.

> The name blends Italian _voce_ (voice) with _tempo_ (time), rooted in the
> Latin _vox_ + _tempus_.

## Features (v1)

- Large clock display (HH:MM), date, and weekday on a 2.42" OLED.
- Spoken time on demand and automatically (hourly / 30 min / 15 min).
- Single-thumbstick control, so the whole UI can be found by feel in the dark.
- Quiet hours: silence automatic announcements overnight (manual still works).
- Automatic daylight saving: pick your region once and the clock adjusts itself
  twice a year, entirely offline. Off by default.
- Fully on-device configuration; settings persist in flash.
- Modular speech clips for compact storage and easy future languages.

## Daylight saving

Under **Settings → Summer time**, choosing a region makes the clock change
itself on the right night, with no internet and nothing to maintain: every
region below switches on an algorithmic rule ("last Sunday in March"), so the
dates are computed on-device and stay correct indefinitely.

| Setting        | Region                                        |
| -------------- | --------------------------------------------- |
| `Off`          | no daylight saving (default)                  |
| `UK/Portugal`  | UK, Ireland, Portugal, Canary Islands         |
| `Europe CET`   | Spain, France, Germany, Italy, Poland, …      |
| `Europe EET`   | Greece, Finland, Romania, the Baltics         |
| `USA/Canada`   | all US and Canadian zones                     |
| `Chile`        | Chile                                         |
| `Australia SE` | NSW, Victoria, South Australia, Tasmania, ACT |
| `New Zealand`  | New Zealand                                   |

Leave it `Off` for anywhere that no longer observes DST, including Brazil,
Argentina, most of Mexico, Russia, Turkey, India, China and Japan.

Choosing a region never changes the time on screen — only what happens on the
transition nights from then on. It can be set at any point, before or after
setting the clock, and in any month.

Internally the DS3231 stores **standard (winter) time** and is never rewritten
for a transition, so the hardware keeps ticking undisturbed; the offset is
applied when the time is read.

## Hardware

- DollaTek ESP32 dev board (ESP-WROOM-32, CP2102, USB-C)
- Hailege 2.42" SSD1309 128x64 OLED (I2C)
- DollaTek DS3231 RTC (I2C)
- DFPlayer Mini + microSDHC (audio)
- CQRobot 3W 4ohm speaker
- KY-023 analog joystick (up/down, left = back, right or click = OK)
- 5V USB wall power

See [`docs/PLAN.md`](docs/PLAN.md) for the staged roadmap,
[`docs/WIRING.md`](docs/WIRING.md) for the pin-by-pin wiring, and
[`docs/ASSEMBLY.md`](docs/ASSEMBLY.md) for soldering and enclosure assembly.

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

# Run the unit tests on your computer (no board required)
pio test -e native
```

The `native` test environment builds only the hardware-free logic — the
daylight-saving rules and the announcement scheduler — so both can be verified
on the host without waiting for a transition night.

## Status

**Stage 1 of 12** — verifying ESP32 programming with a serial "Hello"
heartbeat and onboard LED blink. Hardware peripherals are added one stage at a
time; see the roadmap in `docs/PLAN.md`.

## License

MIT — see [`LICENSE`](LICENSE).
