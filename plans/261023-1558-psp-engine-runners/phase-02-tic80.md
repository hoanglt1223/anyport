---
phase: 2
title: "TIC-80 on PSP"
status: pending
effort: 2-3w
dependsOn: [1]
---

# Phase 02: TIC-80 on PSP

## Requirements

- Build the TIC-80 core (C) with Lua only (other script languages disabled to save memory) for the PSP.
- Output the 240x136 framebuffer as a GE texture drawn at exact 2x (480x272).
- Map the TIC-80 gamepad to PSP buttons; sound through `sceAudio` at the core's sample rate.
- Load `.tic` carts from `ms0:/PSP/GAME/TIC80/carts/`; persistent memory (`pmem`) saved per cart.

## Files (create, in the fork)

- `src/system/psp/main.c`, `src/system/psp/Makefile` or CMake toolchain

## Validation

- 20 popular free carts run at 60 fps on the PSP-3000 with correct sound.

## Risks

- Carts that use the full 256 KB+ RAM features or heavy Lua. Profile with the core's own counters.
