---
title: "Ren'Py to PSP: convert visual novels into native PSP homebrew"
description: "Convert a Ren'Py game's scripts and assets on PC into a compact bytecode and GE-ready textures, played by a small native VN engine on the PSP-3000."
status: pending
priority: P3
effort: 8-12w part-time
branch: main
tags: [feature, experimental, psp, visual-novel]
blockedBy: []
blocks: []
created: 2026-10-23
---

# Ren'Py → PSP

## Overview

Ren'Py needs a full Python runtime and desktop-class memory, so it cannot run on a PSP. Most visual novels, however, use a small part of it: dialogue, menus, jumps, images, transitions, music, and simple variables. `rpy2psp` reads a Ren'Py game on PC (`.rpy` sources, or `.rpyc` compiled scripts and `.rpa` archives), translates that subset into compact VN bytecode, converts images to PSP textures, and packages everything with a native engine `vnpsp` into an EBOOT.

No existing Ren'Py PSP port was found in a quick search; phase 01 confirms.

## Outcome and acceptance criteria

- `rpy2psp build <game-dir>` produces `EBOOT.PBP` plus a data folder, or a clear report of unsupported features with file and line.
- Three free Ren'Py VNs (permissive licenses, for example from itch.io) play start to finish on the PSP-3000, including saves, rollback of at least 50 steps, and Vietnamese or CJK text where the game uses it.
- Load time per scene under 1 second from Memory Stick.

## Non-goals

- Arbitrary Python (custom classes, minigames written in Python, screen-language programs beyond the default UI). Reported as unsupported.
- Live2D, video playback beyond simple MPEG/PSMF cutscenes, voice-acting lip sync.

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Prior-art check and feature census](phase-01-prior-art-and-census.md) | 1w | none | pending |
| 02 | [Script reader and bytecode compiler](phase-02-script-compiler.md) | 3w | 01 | pending |
| 03 | [Asset pipeline](phase-03-asset-pipeline.md) | 2w | 01 | pending |
| 04 | [Native VN engine on PSP](phase-04-vn-engine.md) | 3-4w | 02, 03 | pending |
| 05 | [Bring-up and packaging](phase-05-bring-up-and-packaging.md) | 1-2w | 04 | pending |

## Dependencies

- Platform layer and PSP toolchain setup from `261023-1548-anyswf-flash-to-psp` phase 01 (reuse; same Docker toolchain, same platform interface).
- unrpyc-style `.rpyc` decoding (reference) and `.rpa` archive format (reference).

## Key risks

- Python expressions in conditions and assignments. Compile a safe subset (numbers, strings, booleans, comparisons, arithmetic, `and/or/not`, simple dict/list access); everything else reported.
- Memory: full-screen images at 480x272 in DXT5 are about 130 KB each; stream per scene with an LRU cache.

## Legal model

Tool and engine only. Users convert games they have the right to use; many free VNs allow redistribution, but the tool does not ship any.
