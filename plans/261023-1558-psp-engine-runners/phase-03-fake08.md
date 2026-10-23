---
phase: 3
title: "PICO-8 carts via fake-08"
status: pending
effort: 2w
dependsOn: [1]
---

# Phase 03: PICO-8 carts via fake-08

## Requirements

- Add a PSP host to fake-08 alongside its existing 3DS, Vita, and Switch hosts.
- 128x128 output at 2x (256x256) centred, with an optional stretched mode.
- Input mapping (O/X buttons to Circle/Cross or Cross/Square by setting), sound mixing to `sceAudio`.
- Load `.p8` and `.p8.png` carts from the Memory Stick; cart data saves persisted.
- Use fixed-point Lua as fake-08 does; check speed at 333 MHz.

## Files (create, in the fork)

- `platform/psp/` host files and build script

## Validation

- 20 popular free carts run at full speed (30 or 60 fps) on the PSP-3000.

## Risks

- PNG cart decoding speed on PSP. Cache decoded carts on first load.
