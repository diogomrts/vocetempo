# Vocetempo - Full Wiring Reference

This is the complete wiring for the finished v1 clock. Build it once on the
breadboard and every remaining software stage will work against it.

> Power everything from the ESP32's regulated rails:
> - **3V3** pin -> breadboard "+" rail (3.3 V) for the I2C devices
> - **5V / VIN** pin -> a second "+" rail (5 V) for the DFPlayer
> - **GND** pin -> breadboard "-" rail (shared ground for EVERYTHING)
>
> A shared ground is essential: all devices and buttons must reference the
> same GND or nothing works reliably.

## Pin map (ESP32 -> component)

| ESP32 pin | Goes to                    | Notes                                  |
| --------- | -------------------------- | -------------------------------------- |
| 3V3       | + rail (3.3 V)             | Powers OLED + RTC                       |
| 5V (VIN)  | + rail (5 V)               | Powers DFPlayer                         |
| GND       | - rail (ground)            | Shared by ALL devices and buttons       |
| GPIO 21   | I2C SDA (OLED + RTC)       | Shared data line                        |
| GPIO 22   | I2C SCL (OLED + RTC)       | Shared clock line                       |
| GPIO 27   | DFPlayer RX (via 1k resistor) | ESP32 TX -> DFPlayer RX (30-pin board lacks 16/17) |
| GPIO 14   | DFPlayer TX                | ESP32 RX <- DFPlayer TX                 |
| GPIO 32   | Button UP                  | other side of button -> GND             |
| GPIO 33   | Button DOWN                | other side of button -> GND             |
| GPIO 25   | Button OK                  | other side of button -> GND             |
| GPIO 26   | Button BACK                | other side of button -> GND             |
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

### Buttons (x4) - active-low with internal pull-ups
Each button bridges its GPIO to GND when pressed. We enable the ESP32's
internal pull-up resistors in software (INPUT_PULLUP), so no external
resistors are needed.

| Button | Pin one   | Pin two |
| ------ | --------- | ------- |
| UP     | GPIO 32   | GND     |
| DOWN   | GPIO 33   | GND     |
| OK     | GPIO 25   | GND     |
| BACK   | GPIO 26   | GND     |

## I2C addresses on the bus
- `0x3C` - OLED display
- `0x68` - DS3231 RTC
- `0x57` - AT24C32 EEPROM (on the RTC board; unused in v1)

## Safety notes
- Wire with USB unplugged; plug in only when a step is complete.
- I2C devices on 3.3 V; DFPlayer on 5 V; everything shares GND.
- The 1k resistor on DFPlayer RX protects its input and improves reliability.
