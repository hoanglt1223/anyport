---
phase: 6
title: "Performance and memory tuning on PSP-3000"
status: in-progress
effort: 1-2w
dependsOn: [5]
---

# Phase 06: Performance and memory tuning on PSP-3000

## Context

Games that are playable on PC must hit their frame rate on a 333 MHz CPU with ~52 MB usable RAM and 2 MB VRAM.

## Requirements

- On-device profiler overlay: CPU ms for scripts, display list walk, GE submit; triangle and draw-call counts; heap and VRAM use.
- Texture residency manager: upload on demand, evict least recently used.
- Script hot paths: property lookup caches, avoid allocating numbers (NaN-boxing or small-number cache).
- Matrix and vertex work on the VFPU where profiles show it matters.
- Optional: run audio decode and mixing on the Media Engine.

## Files (modify/create)

- `runtime/src/debug/profiler.c`
- `runtime/src/render/texture_cache.c`
- Hot spots found by profiling in `runtime/src/avm1/*` and `runtime/src/render/*`

## Steps

1. Add the profiler; capture baselines for the three test games.
2. Fix the top three costs per game; repeat.

## Validation

- All three test games hold their SWF frame rate on the PSP-3000 for 10 minutes without memory growth.

Progress (2026-10-25, branch `feat/runtime-builtins`):

- Profiler: `runtime/src/debug/profiler.c` times scripts, timeline, render and present,
  counts draws and triangles, and reports C heap, script heap and VRAM; overlay toggled
  with L+R+Select or `[debug] profiler`, logged with `--profile` (PC) or the setting (PSP);
  warns once over a 40 MB heap.
- Texture residency: `runtime/src/render/texture_cache.c` copies textures into the
  ~688 KB of VRAM left after the frame buffers on first use and evicts least recently
  used ones (never those the current GE list reads); misses draw from RAM.
- PPSSPP measurements (scripted render scenes, not games): both hold 59.9 fps; the
  drawing-API scene went from 4.5 to 0.6 ms of render time per frame after meshes were
  drawn in place, and heap and script heap stay flat over 10 emulated minutes after
  removing a per-frame scope allocation.
- Still open: baselines and tuning for the three test games, VFPU and Media Engine work,
  and every PSP-3000 measurement (no hardware or games on this box). Script hot-path
  caches wait for real game profiles.

## Risks

- Some games are simply too heavy (huge vector scenes). Mark them "too heavy" in the compat list rather than chasing them.

## Rollback

Profiling changes are additive; revert individual optimisations if they regress correctness tests.
