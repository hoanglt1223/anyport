---
phase: 6
title: "Performance and memory tuning on PSP-3000"
status: pending
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

## Risks

- Some games are simply too heavy (huge vector scenes). Mark them "too heavy" in the compat list rather than chasing them.

## Rollback

Profiling changes are additive; revert individual optimisations if they regress correctness tests.
