# Vocetempo - Full Wiring Reference

This is the complete wiring for the finished v1 clock. Build it once on the
breadboard and every remaining software stage will work against it.

> Power everything from the ESP32's regulated rails:
> - **3V3** pin -> breadboard "+" rail (3.3 V) for the I2C devices and the joystick
> - **5V / VIN** pin -> a second "+" rail (5 V) for the DFPlayer only
> - **GND** pin -> breadboard "-" rail (shared ground for EVERYTHING)
>
> A shared ground is essential: every device must reference the same GND or
> nothing works reliably. Only the DFPlayer goes on 5 V.

For assembling this permanently - soldering order, the slide-out sled, and the
speaker mount - see [`ASSEMBLY.md`](ASSEMBLY.md).

## Pin map (ESP32 -> component)

| ESP32 pin | Goes to                    | Notes                                  |
| --------- | -------------------------- | -------------------------------------- |
| 3V3       | + rail (3.3 V)             | Powers OLED + RTC                       |
| 5V (VIN)  | + rail (5 V)               | Powers DFPlayer                         |
| GND       | - rail (ground)            | Shared by ALL devices                   |
| GPIO 21   | I2C SDA (OLED + RTC)       | Shared data line                        |
| GPIO 22   | I2C SCL (OLED + RTC)       | Shared clock line                       |
| GPIO 27   | DFPlayer RX (via 1k resistor) | ESP32 TX -> DFPlayer RX (30-pin board lacks 16/17) |
| GPIO 14   | DFPlayer TX                | ESP32 RX <- DFPlayer TX                 |
| GPIO 32   | Joystick VRx               | analog, ADC1_CH4                        |
| GPIO 33   | Joystick VRy               | analog, ADC1_CH5                        |
| GPIO 25   | Joystick SW                | press-down switch -> GND, internal pull-up |
| GPIO 26   | *free*                     | was Button BACK; spare for v2           |
| GPIO 2    | onboard LED                | built-in, no wiring                     |

## Per-device wiring

### OLED (SSD1309, I2C) - 3.3 V
| OLED | Rail / ESP32 |
| ---- | ------------ |
| GND  | - rail       |
| VDD  | + rail (3.3V)|
| SCL  | GPIO 22      |
| SDA  | GPIO 21      |

### DS3231 RTC (I2C) - 3.3 V
| RTC  | Rail / ESP32 |
| ---- | ------------ |
| GND  | - rail       |
| VCC  | + rail (3.3V)|
| SDA  | GPIO 21      |
| SCL  | GPIO 22      |
(SQW and 32K pins unused. Onboard AT24C32 EEPROM appears at I2C 0x57.)

### DFPlayer Mini (UART) - 5 V
| DFPlayer pin | Connect to                          |
| ------------ | ----------------------------------- |
| VCC          | + rail (5 V)                        |
| GND          | - rail                              |
| RX           | GPIO 27 **through a 1k resistor**   |
| TX           | GPIO 14                             |
| SPK_1        | speaker wire 1                      |
| SPK_2        | speaker wire 2                      |
(Use SPK_1/SPK_2 for the bare speaker. Do NOT use DAC_L/DAC_R for a passive
speaker. microSD card goes into the DFPlayer, not the ESP32.)

### Speaker (CQRobot 3W 4ohm)
| Speaker | Connect to     |
| ------- | -------------- |
| wire 1  | DFPlayer SPK_1 |
| wire 2  | DFPlayer SPK_2 |

IMPORTANT - the DFPlayer output is MONO and BRIDGE-TIED (BTL):
- SPK_1 and SPK_2 are the TWO TERMINALS OF ONE SPEAKER, not left/right.
- NEITHER pin is ground. Do NOT connect a speaker wire to GND.
- Do NOT tie SPK_1 and SPK_2 together.
- Use ONE speaker across SPK_1/SPK_2. (Two speakers only in SERIES = 8 ohm;
  never in parallel = 2 ohm, which overheats the amp.)
- Polarity does not matter for a single speaker.
- Wiring a speaker pin to GND or shorting SPK_1+SPK_2 shorts the 8002B amp
  and makes it overheat.

### Joystick (KY-023 analog thumbstick) - 3.3 V
Replaces the four push buttons. Five pins, and the labels vary slightly between
batches (`VRx`/`VRy` are sometimes `X`/`Y`, `SW` sometimes `SEL` or `B`).

| KY-023 pin | Connect to        | Notes                                     |
| ---------- | ----------------- | ----------------------------------------- |
| GND        | - rail            | shared ground                             |
| +5V / VCC  | **+ rail (3.3 V)** | see the warning below - NOT the 5 V rail |
| VRx        | GPIO 32           | analog axis                               |
| VRy        | GPIO 33           | analog axis                               |
| SW         | GPIO 25           | shorts to GND when pushed down            |

> **Power it from 3.3 V, even though the pin says "+5V".**
> The axes are potentiometer dividers across whatever you feed them, so on 5 V
> they would swing to 5 V and be fed straight into a GPIO. The ESP32's ADC pins
> are 3.3 V devices: anything above ~3.3 V reads pinned at maximum and risks
> damaging the pin. The module has no regulator and works perfectly on 3.3 V -
> the only effect is that full deflection reads 4095 instead of clipping.

No external resistors are needed. `SW` uses the ESP32's internal pull-up
(`INPUT_PULLUP`), so it reads HIGH idle and LOW when pressed, exactly like the
buttons it replaces. The two axis pins get no pull-up - that would fight the
potentiometer.

**Action mapping** (`include/Buttons.h`):

| Stick movement    | Logical action | Effect on the clock face          |
| ----------------- | -------------- | --------------------------------- |
| up / down         | UP / DOWN      | pet the panda; scroll in menus     |
| left              | BACK           | tap speaks the time, hold mutes    |
| right             | OK             | open the menu / confirm            |
| push down (click) | OK             | same as right                      |

**Confirm the orientation after wiring** - which way each potentiometer swings
depends on how the module is mounted:

```sh
pio run -e joystick_test -t upload
pio device monitor -b 115200
```

Idle should read `x` and `y` near 1900-2100 with `dir=None`, and `sw=1` falling
to `0` when clicked. Push the way you want "up" to mean: if it prints `Down`,
set `kInvertY = true` in `src/Buttons.cpp`; if left/right are swapped, set
`kInvertX = true`. If pushing up prints `Left`/`Right`, the two axis wires are
swapped - exchange VRx and VRy.

## I2C addresses on the bus
- `0x3C` - OLED display
- `0x68` - DS3231 RTC
- `0x57` - AT24C32 EEPROM (on the RTC board; unused in v1)

## Safety notes
- Wire with USB unplugged; plug in only when a step is complete.
- I2C devices on 3.3 V; DFPlayer on 5 V; everything shares GND.
- The 1k resistor on DFPlayer RX protects its input and improves reliability.
