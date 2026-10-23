---
title: "AnyPSP: generic PSP static recompiler with HLE runtime for PC, ARM handhelds, and Android"
description: "Build a game-agnostic PSP-to-native pipeline (Allegrex/VFPU to C++, HLE of PSP system modules, GE to Vulkan) with tracked library coverage, targeting Windows, Linux, macOS, and Android/ARM handhelds."
status: pending
priority: P1
effort: 6-12 months part-time
branch: main
tags: [feature, experimental, recompiler, hle, psp]
blockedBy: []
blocks: []
created: 2026-10-23
---

# AnyPSP

## Overview

Static recompilation of PSP games already works for individual titles, through several separate frameworks (details in `repos/anypsp/docs/dev/prior-art.md`):

- jessicanataliagta/PSPRecomp (C++20, MIT): GTA LCS/VCS and God of War ports; snuri00/psp-web-recomp builds on it with a game-agnostic one-script pipeline.
- sp00nznet/psprecomp (C11, MIT), forked by zmbkilla for the PSP2i port.
- wizardengineer/psprecomp (Rust, GPL-2.0; Patapon).
- sal063's Ace Combat X recomp (GPL-2.0).

Those efforts keep HLE and rendering largely per game. Phase 01 recommends forking PSPRecomp at `f6e7d41` with psp-web-recomp's patches and its generic host, licensed GPL-2.0-or-later.

AnyPSP aims at what AnyPS5 does for PS5: a **game-agnostic** pipeline with HLE reimplementations of PSP system modules, public coverage tracking, and more hosts (ARM64 Android and handhelds, not only Windows). Phase 01 decides whether that means contributing to or forking PSPRecomp, or starting fresh. Reuse is the default.

## Outcome and acceptance criteria

- `anypsp build EBOOT.BIN` (decrypted, from the user's own UMD/PSN dump) produces a native executable for Windows x64, Linux x64/arm64, macOS arm64, and an Android arm64 APK.
- Five titles of different genres reach in-game; two are playable start to finish.
- Coverage badges for HLE functions (by NID), VFPU opcodes, and GE commands, published like AnyPS5's progress page.
- No firmware, keys, or game data shipped.

## Non-goals

- Running PSP firmware modules (LLE). Everything system-side is HLE.
- Ad-hoc networking, UMD video playback, camera and GPS peripherals.

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Evaluate PSPRecomp and prior ports, choose base](phase-01-evaluate-prior-art.md) | 2w | none | completed |
| 02 | [Loader and analysis: PRX, relocations, NIDs, function discovery](phase-02-loader-and-analysis.md) | 4-6w | 01 | completed |
| 03 | [Code generation: Allegrex and VFPU to C++](phase-03-codegen-allegrex-vfpu.md) | 6-8w | 02 | pending |
| 04 | [HLE kernel and system modules](phase-04-hle-modules.md) | 8-12w | 03 | pending |
| 05 | [GE renderer on Vulkan](phase-05-ge-vulkan-renderer.md) | 8-12w | 04 | pending |
| 06 | [Hosts: desktop, Android, ARM handhelds](phase-06-hosts.md) | 3-4w | 05 | pending |
| 07 | [Game bring-up and coverage tracking](phase-07-bring-up-and-coverage.md) | ongoing | 06 | pending |

## Dependencies

- PSPRecomp and its downstream ports (license and code quality decided in phase 01).
- PPSSPP (GPL-2.0+) as the behaviour reference for HLE modules, GE, and VFPU. Copying code requires a GPL-compatible project license.
- Shares the compat tracker format with AnyGBA (`261023-1514-anygba-static-recompiler`).

## Key risks

- VFPU: 128 registers addressable as matrices, rows, and columns with prefixes. Translating it correctly and fast is the hardest CPU part.
- Games load extra PRX modules and overlays at runtime. The pipeline must recompile every module found on the disc, not only `EBOOT.BIN`.
- Duplicating PSPRecomp. Phase 01 is a gate to avoid that.

## Legal model

Tool only. Users decrypt their own dumps. No firmware or keys.
