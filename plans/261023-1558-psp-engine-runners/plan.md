---
title: "PSP engine runners: TIC-80, PICO-8 (fake-08), modern LÖVE, GameMaker 8"
description: "Bring four game-engine runners to the PSP-3000 by porting existing open-source reimplementations, so whole libraries of small games run on it unmodified."
status: pending
priority: P3
effort: 10-16w part-time (all four)
branch: main
tags: [feature, psp, runtime-port]
blockedBy: []
blocks: []
created: 2026-10-23
---

# PSP engine runners

## Overview

Each runner is a port of an existing open-source reimplementation to the PSP, done as a fork of its upstream so fixes can flow back. Ordered by fit and value:

| Runner | Upstream | Why it fits the PSP | Prior art on PSP |
|---|---|---|---|
| TIC-80 | TIC-80 (MIT) | Native resolution 240x136 scales exactly 2x to the PSP's 480x272 | None found; phase 01 checks |
| PICO-8 carts | fake-08 (MIT), already on 3DS/Vita/Switch | 128x128 scales 2x to 256x256, fits the 272-pixel height | None found; phase 01 checks |
| LÖVE 11 | LövePotion (rewrite of LÖVE APIs for homebrew) | Lua runs well at 333 MHz; LÖVE 11 is the current game base | LovePSP exists but targets LÖVE 0.8 and was abandoned in 2014 |
| GameMaker 8 | OpenGMK (Rust) | Large library of 2000s GM8 games | Unknown; phase 01 checks |

## Outcome and acceptance criteria

- Each runner ships as an EBOOT that lists games from a Memory Stick folder.
- TIC-80 and PICO-8: 20 popular free carts each run at full speed (60 fps / 30 fps) with sound.
- LÖVE: five small LÖVE 11 games run unmodified at 30 fps or better.
- GM8: three small GM8 games run, or a documented no-go with measurements.
- PICO-8: no PICO-8 binaries or BIOS used; only cart files the user has.

## Non-goals

- Editors (TIC-80 and PICO-8 editors stay off; play mode only).
- LÖVE shaders (`love.graphics.newShader`), since the GE has no programmable shaders. Reported as unsupported.

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Prior-art check and shared PSP layer](phase-01-prior-art-and-shared-layer.md) | 1w | AnySWF phase 01 | pending |
| 02 | [TIC-80 on PSP](phase-02-tic80.md) | 2-3w | 01 | pending |
| 03 | [PICO-8 carts via fake-08](phase-03-fake08.md) | 2w | 01 | pending |
| 04 | [LÖVE 11 via LövePotion](phase-04-love.md) | 3-4w | 01 | pending |
| 05 | [GameMaker 8 via OpenGMK (spike first)](phase-05-gm8.md) | 2-6w | 01 | pending |

Phases 02-05 are independent and can run in parallel.

## Repo strategy

One fork per runner (`tic-80`, `fake-08`, `lovepotion`, `opengmk`), each with a `psp` platform backend. The shared PSP platform layer from AnySWF is vendored as a small library.

## Key risks

- Upstream acceptance of a PSP backend. Ask maintainers early; keep the fork rebased if they decline.
- Memory: Lua heaps and GM8 games with large sprites. Measure per game and report "too big" honestly.
