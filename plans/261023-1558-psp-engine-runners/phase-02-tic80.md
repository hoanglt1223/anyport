---
phase: 2
title: "TIC-80 on PSP"
status: in-progress
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

## Status notes (2026-10-24)

- Fork: `repos/tic80-psp`, branch `psp` (upstream nesbox/TIC-80 at f6ff942). Build: `src/system/psp/build.sh`
  (pspdev Docker), EBOOT at `out/psp/bin/EBOOT.PBP`. Not pushed.
- Done: CMake PSP target, Lua-only play-only player, cart browser (a TIC-80 Lua cart), `.tic` and `.lua`
  project carts from `ms0:/PSP/GAME/TIC80/carts/`, 2x GE blit, sceAudio through a lock-free ring (host
  test `psp-audio-ring-test`), pmem per cart, Start+Select back to the list, fps/tick log every 5 s.
- Float everywhere it matters: `LUA_32BITS` and a float triangle rasteriser on PSP. In PPSSPPHeadless the
  float build lifts fire.lua 15 -> 60 fps, p3d.lua 7.8 -> 30, quest.lua 30 -> 56, car.lua 8.5 -> 30.
- PPSSPPHeadless: 10 of 12 TIC-80 demo carts at 60 fps; p3d and car at 30. Empty cart costs 3.7 ms per
  tick (core tick plus RGBA blit), sound 0.3 ms.
- Open: 20 popular free carts on the PSP-3000 with sound (hardware run via psplink), `.png` carts,
  GE-side palette blit to cut the 3.4 ms base cost. Details: `plans/reports/fullstack-developer-261024-1741-engine-runners.md`.
