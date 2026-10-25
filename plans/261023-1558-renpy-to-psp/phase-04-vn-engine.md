---
phase: 4
title: "Native VN engine on PSP"
status: in-progress
effort: 3-4w
dependsOn: [2, 3]
---

# Phase 04: Native VN engine on PSP

## Context

`vnpsp` is a small C engine on the shared PSP platform layer. It interprets the compact bytecode (cheap compared with Python) and draws with the GE.

## Requirements

- Bytecode interpreter with call stack, variables, and deterministic state for saves and rollback.
- Scene graph for backgrounds and sprites with tags, layers, ATL subset animations, and transitions on the GE.
- Text box with typewriter effect, text tags, NVL mode, history log, auto and skip modes.
- Menus navigable with the D-pad and analog nub.
- Saves: 30 slots with thumbnails in `ms0:/PSP/SAVEDATA/`, quick save/load, rollback of at least 50 steps (snapshot ring buffer).
- Settings: text speed, volumes, auto speed.
- Streaming asset loader with LRU texture cache in RAM and VRAM.

## Files (create)

- `vnpsp/src/vm.c`, `scene.c`, `atl.c`, `transitions.c`, `text.c`, `menu.c`, `save.c`, `rollback.c`, `settings.c`, `assets.c`, `audio.c`
- Platform layer imported from AnySWF

## Steps

1. VM and text, then scenes and sprites.
2. Transitions and ATL.
3. Saves, rollback, settings.
4. Streaming and memory tuning.

## Validation

- First target game plays start to finish on PPSSPP, then on the PSP-3000.

## Rollback

Module-scoped; revert.

## PSP-side results (2026-10-25, Linux box)

Engine EBOOT built with psp-gcc in the pinned pspdev image (`scripts/psp-build.sh`, no warnings in our code), wrapped by `rpy2psp build`, and run in PPSSPPHeadless. Games: full checkouts of the three targets at the census commits in `/home/ubuntu/anyport-scratch/rpy2psp-games` (outside the repo). Tools: `tests/psp/ppsspp_run.py`, `tests/psp/music_loop_check.py`.

- [x] Frames vs PC shots: The Question timeline (title, 9 lines, menu choice, save, load, rest of the ending, back to the title) gives 17 shots at 31-51 dB PSNR against the PC engine; the two lowest differ only in the save timestamp. Japanese build, Zero Echoes (Chinese) and Arcance openings: 36-52 dB. Covers GE DXT/CLUT drawing, VRAM pool, transitions, thumbnails, CJK.
- [x] Saves at `ms0:/PSP/SAVEDATA/<folder>/`: `slot-01.sav` and `persistent.bin` written to `PSP/SAVEDATA/TheQuestion/`; loading slot 1 returns to the saved line.
- [x] Music loop: the PSP mix of a self-made 2 s loop equals the PC engine's within 1 LSB over five loops (PPSSPP audio dump).
- [x] minimp3 cost (emulated, indicative): mixer with MP3 decoding 4.4-5.3% of real time; frame CPU 0.2-0.5 ms average at 59.9 fps.
- [x] Load time < 1 s (emulated I/O): start-up 54-70 ms; first scenes 155-348 KB in 16-36 ms. A save or load stalls one frame for about 0.3 s.
- [ ] Real PSP-3000 (ARK-4) via psplink: real Memory Stick timing, minimp3 at 333 MHz on hardware, memory headroom. Needs the hardware; this phase stays in progress until then.

Fixes found on the way: `strcasecmp` is not declared in C11 mode on glibc (Linux build failed); `psp-build.sh` now works from `sh` and keeps `out/psp` user-owned. The engine now logs start-up, scene load and a 5 s perf line through `plat_log`.
