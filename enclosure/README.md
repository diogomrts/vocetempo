# Vocetempo enclosure

Parametric 3D-printable case for the panda-themed talking clock, written in
[OpenSCAD](https://openscad.org). The theme is a **sitting panda holding the
OLED screen in its paws**, echoing the panda face the firmware draws on that
screen.

## Files

| File | Purpose |
| ---- | ------- |
| `dimensions.scad` | All component measurements in ONE place. **Edit here.** |
| `helpers.scad` | Shared shape modules (rounded box, ear, OLED window, grille, screw boss). |
| `concept1_chubby_panda.scad` | Round, cuddly panda cradling the screen. |
| `concept2_box_panda.scad` | Stouter rounded-box panda; flat faces = easy print. |
| `concept3_minimal_panda.scad` | Minimalist geometric panda presenting a tilted screen. |
| `render_previews.sh` | Renders `previews/*.png` for all concepts. |

These concept files are **massing models** (solid shapes to judge the look).
Once a concept is chosen we develop it into printable parts: hollow shell split
into front/back, internal standoffs/bosses, panel cutouts, a **bottom SD hatch**,
and port openings.

## Rendering previews

```sh
brew install --cask openscad      # once
cd enclosure
./render_previews.sh              # writes previews/concept*.png
```

Or open any `.scad` in the OpenSCAD GUI and press F5 (preview) / F6 (render).

## IMPORTANT: measure before printing a final case

The numbers in `dimensions.scad` are **nominal** (typical values). ESP32/RTC/
DFPlayer clones vary by a couple of mm. Before exporting a final STL, measure
YOUR boards with calipers and update `dimensions.scad`. Fields marked
`[verify]` are the ones most likely to differ.

## Serviceability (baked into the design intent)

- **SD card stays removable:** the DFPlayer is socketed on female headers above
  a removable **bottom hatch**; pop the hatch to reach the microSD slot without
  opening the shell. See `docs/WIRING.md` for the electrical side.
- **No hard-soldered modules:** ESP32, DS3231 and DFPlayer sit in header
  sockets on a perfboard base, so any module (or the RTC battery) can be
  replaced.
- **Amp airflow:** vent slots near the DFPlayer (the 8002B runs warm).
