---
phase: 3
title: "PICO-8 carts via fake-08"
status: in-progress
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

## Status notes (2026-10-24)

- Fork: `repos/fake08-psp`, branch `psp` (upstream jtothebell/fake-08 at 814991a). Build:
  `platform/psp/build.sh` (pspdev Docker, applies `z8lua-psp-int-types.patch` to the submodule), EBOOT at
  `out/psp/EBOOT.PBP`. Not pushed.
- Done: PSP host on the shared layer, T4 texture plus 16-entry CLUT drawn at 2x (draw modes, flips and
  rotations included), 22050 Hz synth doubled to 44.1 kHz, carts from `<EBOOT dir>/carts`, cartdata and
  settings under `ms0:/PSP/SAVEDATA/FAKE08/`, L+R quit, fps log every 5 s.
- Input: Cross/Triangle are PICO-8 X (the menu runs carts with X, as on Vita), Circle/Square are O. The
  plan's "by setting" choice and the stretched mode are not done.
- PPSSPPHeadless: BIOS menu, `ld45.p8` (in the upstream repo) and a self-authored stress cart (120
  circles, 32 lines) run at 60 fps; stress uses 12 ms of a 16.7 ms frame.
- Open: 20 popular free carts on the PSP-3000 and comparison with Frog08, `.p8.png` load speed. Details:
  `plans/reports/fullstack-developer-261024-1741-engine-runners.md`.
