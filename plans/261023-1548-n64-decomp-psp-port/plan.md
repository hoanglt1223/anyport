---
title: "Port an N64 decompilation project natively to the PSP-3000"
description: "Take a completed N64 decompilation (or its PC port), replace the N64 OS and graphics layer with a PSP backend, and ship a native EBOOT that extracts assets from the user's own ROM."
status: pending
priority: P2
effort: 10-16w part-time
branch: main
tags: [feature, experimental, psp, n64, decomp, port]
blockedBy: []
blocks: []
created: 2026-10-23
---

# N64 decomp → PSP native port

## Overview

Several N64 games have complete decompilations with PC ports: Star Fox 64 (Starship), Mario Kart 64 (SpaghettiKart), and Ocarina of Time (Ship of Harkinian). The last three share `libultraship`, which renders N64 display lists through a "Fast3D" interpreter with pluggable graphics backends. Super Mario 64 also has older, lighter PC ports (sm64-port) built on a small C Fast3D.

Because the game logic is already C source, a PSP port means:

1. Replacing the N64 OS calls (libultra: controllers, threads, timers, audio, video swap) with pspsdk equivalents.
2. Writing a Fast3D backend that draws on the PSP GPU (GE), mapping the N64 color combiner onto GE texture functions.
3. Fitting the game into ~52 MB of usable RAM and 2 MB of VRAM.

**Update after phase 01 research:** Super Mario 64, Mario Kart 64, and Ocarina of Time already have native PSP ports, and Majora's Mask and Star Fox 64 are in progress (see `reports/researcher-261023-1741-n64-decomp-survey.md`). Decision: target **Paper Mario**, the only candidate without a PSP port, on route B (original decomp + slim C Fast3D), with our own renderer code (the widely copied sm64-port Fast3D files carry no license). Every working PSP port uses route B, so route A (libultraship) is dropped. Phase 01 measurements still need the user's own ROM.

## Outcome and acceptance criteria

- One game boots on a real PSP-3000 (ARK-4 CFW) from an EBOOT plus assets extracted from the user's ROM.
- The first level or area is playable start to finish at a stable frame rate (target 30 fps; 20 fps minimum).
- Saves work on the Memory Stick.
- No ROM, extracted asset, or copyrighted data is committed or distributed.

## Non-goals

- Enhancements from the PC ports (widescreen hacks beyond 16:9 fit, high-res packs, mods, ImGui menus).
- Supporting every game in the libultraship family in this plan. A second game is a follow-up plan.

## Repo strategy

One repo per game, as a fork of the chosen upstream (decomp or PC port). That keeps upstream history and licensing intact and allows pulling upstream fixes. A shared `n64-psp-shim` library is extracted only when a second game is ported.

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Prior-art check, game choice, and route spike](phase-01-survey-and-route-spike.md) | 2w | none | pending |
| 02 | [PSP platform shim for libultra](phase-02-libultra-psp-shim.md) | 2-3w | 01 | pending |
| 03 | [Fast3D GE renderer backend](phase-03-fast3d-ge-backend.md) | 3-4w | 02 | pending |
| 04 | [Audio](phase-04-audio.md) | 1-2w | 02 | pending |
| 05 | [Memory and performance on PSP-3000](phase-05-memory-and-performance.md) | 2-3w | 03, 04 | pending |
| 06 | [Asset extraction, packaging, release](phase-06-assets-packaging-release.md) | 1w | 05 | pending |

Phases 03 and 04 can run in parallel.

## Key risks

- `libultraship` is C++ and memory-hungry (resource archives, caches). If phase 01 measures a peak heap far above 52 MB, use route B: the original decomp plus a slim C Fast3D, as sm64-port does.
- The N64 color combiner has modes the GE cannot express. Map common combiner presets; approximate the rest; list visible differences.
- CPU budget: N64 games run at 20-30 fps on a 93.75 MHz CPU with an RSP for geometry. On PSP the CPU does game logic plus display-list processing, so the VFPU must take the matrix and vertex work.

## Legal model

Same as the upstream projects: assets come only from the user's ROM, extracted on PC or on first launch.
