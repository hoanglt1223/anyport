---
phase: 4
title: "LÖVE 11 via LövePotion"
status: pending
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
