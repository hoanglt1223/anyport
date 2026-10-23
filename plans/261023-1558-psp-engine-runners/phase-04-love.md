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
