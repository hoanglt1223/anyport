---
phase: 4
title: "LÖVE 11 via LövePotion"
status: in-progress
effort: 3-4w
dependsOn: [1]
---

# Phase 04: LÖVE 11 via LövePotion

## Requirements

- Add a PSP backend to LövePotion (its graphics, audio, input, and filesystem backends are per-platform already).
- `love.graphics` on the GE: images, quads, sprite batches, canvases (render to texture), text with TTF fonts pre-rasterised at load, primitives, blend modes the GE supports; shaders reported as unsupported.
- `love.audio` with OGG/MP3/WAV sources (OGG decoded on CPU; prefer MP3 on the Media Engine), `love.keyboard`/`love.joystick` mapped from PSP buttons, `love.filesystem` on the Memory Stick.
- Scale games designed for 800x600 or 1280x720 to 480x272 with letterboxing; per-game config for scaling and controls.
- Load `.love` files from a folder.

## Files (create, in the fork)

- `platform/psp/` backend modules and build script

## Validation

- Five small LÖVE 11 games run unmodified at 30 fps or better.

## Risks

- Lua memory use on big games. Use a tuned allocator and report heap use on screen in debug builds.

## Status notes (2026-10-24)

- Fork cloned to `repos/lovepotion-psp`, local branch `psp` based on `origin/3.1.0-development` (666f626,
  2026-10-20): the active rewrite, LÖVE 12 API, platform code under `platform/<name>/` (3DS: about 5k
  lines). No PSP code yet.
- Porting surface found: graphics backend (Graphics, Texture, Buffer, StreamBuffer, Shader stubs, Font),
  a software mixer for the voice-based audio driver, joystick/keyboard/system/timer/window, boot. Lua 5.1
  is not in pspdev (it ships 5.4), so the fork has to build Lua 5.1 itself, with float numbers. Box2D in
  pspdev is v3; the 3.1 branch has no love.physics. Details: `plans/reports/fullstack-developer-261024-1741-engine-runners.md`.

## Status notes (2026-10-24, evening)

- **Backend done, hardware test pending.** `repos/lovepotion-psp`, branch `psp` (local commits only):
  - Platform code is in `platform/psp/`, with Lua 5.1.5 vendored in `libraries/lua51`. It has float numbers by default and `goto` support.
  - `platform/psp/build.sh` builds the EBOOT in the pspdev Docker image.
  - `platform/psp/run-headless.sh` runs a game in PPSSPPHeadless.
  - Build, controls, conf.lua options and limits are in `platform/psp/README.md`.
- **Requirements, as built:**
  - GE rendering covers images, quads, sprite batches, canvases (in VRAM), text (FreeType, with Vera as the default font), primitives and the GE blend modes. Shaders report as unsupported.
  - Audio is decoded on the CPU and mixed in software. OGG, MP3 and WAV are tested; FLAC and tracker formats are built but untested. Media Engine MP3 is not used.
  - The buttons drive `love.joystick` and keyboard keys. The mapping can be changed per game with `t.psp.keys`.
  - Save data is written to `ms0:/PSP/SAVEDATA/LOVEPOTION`.
  - The game window is letterboxed onto 480x272. `t.psp.scale` can choose fit, stretch or integer scaling.
  - A game loads from `game/` or `game.love` next to the EBOOT.
- **Validation (PPSSPPHeadless, 60 fps target):**
  - Four unmodified open-source LÖVE 11 games run end to end at 58-60 fps:
    - GoldMiner-Rebirth (MIT)
    - love-tetronimo (MIT; it needs `goto`)
    - Gravity-Wars (MIT)
    - a Pong clone (MIT), loaded as `game.love`
  - The no-game screen and self-authored tests (`platform/psp/tests/smoke` and `lua-goto`) pass.
  - A fifth game, Floppy (MIT), stops on its own `setPitch(math.random(0.9, 1.1))`. That call can return 0, and desktop LÖVE fails on it too.
  - No game data is committed.
- **Float Lua:**
  - `tests/lua-bench` runs arithmetic 10x faster and table loops 2.5x faster than double Lua.
  - The cost is precision: integers are exact only up to 2^24.
  - Float stays the default; `-DLOVE_PSP_LUA_FLOAT=OFF` builds with doubles.
- **Left to do:**
  - Run the EBOOT on the PSP-3000 and check frame times and audio.
  - Add an on-screen keyboard for text input.
  - Add mouse emulation; `love.mouse` is a stand-in today.
  - Find a fifth game.
- **Report:** `plans/reports/fullstack-developer-261024-1844-lovepotion-psp.md`.
