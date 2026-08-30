# zmk-config-silakka54

ZMK firmware config for a Silakka54 wireless split (nice!nano v2 + nice!view).

Shield definition derived from [AnshulJ98/zmk-config-silakka54](https://github.com/AnshulJ98/zmk-config-silakka54) (MIT).
The keymap here is a plain QWERTY starting point, meant to be customised
live in [ZMK Studio](https://zmk.studio) rather than by reflashing.

## Layers
- **Base** — QWERTY, real modifiers
- **Lower** — F-keys, symbols, arrows
- **Raise** — numbers, media
- **Adjust** (Lower+Raise) — Bluetooth profiles, output toggle, bootloader

## Flashing
Download the artifacts from the latest Actions run. Double-tap reset on a
half, it mounts as `NICENANO`, copy the matching `.uf2` on.
