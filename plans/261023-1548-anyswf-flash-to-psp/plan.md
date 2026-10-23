---
title: "AnySWF: compile Flash (AS1/AS2) games ahead of time into native PSP homebrew"
description: "Turn a SWF file into a PSP EBOOT by compiling its ActionScript bytecode to C and tessellating its vector art into triangle meshes at build time, with a small native runtime for the display list and Flash APIs."
status: in-progress
priority: P2
effort: 12-16w part-time
branch: main
tags: [feature, experimental, psp, flash, aot-compiler]
blockedBy: []
blocks: []
created: 2026-10-23
---

# AnySWF: Flash → PSP

## Overview

The PSP-3000 is too slow to interpret Flash and rasterise vector graphics on the CPU, which is why no usable Flash player exists for it. AnySWF moves the expensive work to build time on a PC:

- ActionScript 1/2 bytecode (AVM1) is compiled to C, so there is no bytecode interpreter at runtime.
- Vector shapes are tessellated into triangle meshes, which the PSP GPU (GE) draws fast.
- Bitmaps are converted to swizzled, palettised PSP textures that fit in 2 MB of VRAM.

The output is an `EBOOT.PBP` that runs on a PSP with custom firmware (ARK-4). The same runtime also builds for PC with SDL3, for fast debugging.

## Outcome and acceptance criteria

- `anyswf build game.swf` produces `EBOOT.PBP` and a PC debug executable.
- Self-authored AS2 test SWFs (compiled with the open-source MTASC compiler) pass a conformance suite on both targets.
- Three classic AS2 mini games run at their native frame rate (typically 24-30 fps) on a real PSP-3000.
- Save data through `SharedObject` persists on the Memory Stick.
- No SWF content is shipped with the project.

## Non-goals

- ActionScript 3 (AVM2). A later plan, only if AS2 succeeds.
- Network features (`getURL`, `XML.load` over HTTP, `LocalConnection`), video (`FLV`), microphone and webcam.
- Pixel-exact anti-aliased rendering.

## Architecture

```
PC build time                                           PSP runtime (C, pspsdk)
game.swf ─► swf2c (Rust)                                libswfrt
            ├─ parse SWF tags (ruffle `swf` crate)      ├─ display list + timeline (place/move/remove per frame)
            ├─ AVM1 bytecode ─► C (dynamic value model) ├─ AVM1 value/object model, GC, built-in classes
            ├─ shapes/morphs/glyphs ─► lyon meshes      ├─ GE renderer: meshes, gradients, bitmaps, masks (stencil)
            ├─ bitmaps ─► swizzled CLUT8/5551 textures  ├─ sound: sceAudio PCM/ADPCM + MP3 via Media Engine
            └─ sounds ─► ADPCM / keep MP3               ├─ input: analog nub cursor, buttons ─► keys/mouse
                     │                                  └─ platform: psp/ and sdl/ backends
                     └─► game.c + assets.bin ─► psp-gcc ─► EBOOT.PBP
```

## Phases

| # | Phase | Effort | Depends on | Status |
|---|---|---|---|---|
| 01 | [Repo, PSP toolchain, platform layer, test corpus](phase-01-repo-toolchain-platform.md) | 1-2w | none | in-progress |
| 02 | [SWF parsing and asset pipeline](phase-02-swf-parsing-and-assets.md) | 2w | 01 | completed |
| 03 | [GE renderer and display list](phase-03-ge-renderer-and-display-list.md) | 3w | 02 | pending |
| 04 | [AVM1 ahead-of-time compiler](phase-04-avm1-aot-compiler.md) | 3-4w | 02 | in-progress |
| 05 | [Runtime built-ins: MovieClip, Key, Mouse, Sound, SharedObject](phase-05-runtime-builtins.md) | 2-3w | 03, 04 | pending |
| 06 | [Performance and memory tuning on PSP-3000](phase-06-psp-performance.md) | 1-2w | 05 | pending |
| 07 | [Game bring-up and compatibility list](phase-07-game-bring-up.md) | ongoing | 06 | pending |
| 08 | [Native PC and Android export](phase-08-pc-android-export.md) | 2w | 05 | pending |

Phases 03 and 04 can run in parallel.

## Dependencies

- Ruffle's `swf` crate (MIT/Apache-2.0) for parsing; `lyon` (MIT/Apache-2.0) for tessellation. Ruffle's AVM1 behaviour and test SWFs are the semantic reference.
- pspdev toolchain (psp-gcc, pspsdk), PPSSPP for fast iteration, psplink for on-device debugging.
- Hardware: the user's PSP-3000 with ARK-4.

## Key risks

- AVM1 is fully dynamic (string paths like `_root.mc.x`, `with`, prototype chains). AOT removes dispatch cost but not dynamic lookups. Mitigate with interned strings, cached slot lookups, and constant-path resolution at compile time.
- 2 MB VRAM and ~52 MB usable RAM. Mitigate with CLUT8 textures, on-demand texture upload, and mesh LOD by display scale.
- Masks and color transforms on the fixed-function GE. Masks use the stencil buffer (8888 framebuffer); additive color transforms use a second blend pass.

## Legal model

Tool and runtime only. Users supply SWF files they have the right to use.
