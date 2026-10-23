---
phase: 5
title: "Memory and performance on PSP-3000"
status: pending
effort: 2-3w
dependsOn: [3, 4]
---

# Phase 05: Memory and performance on PSP-3000

## Context

Getting a picture is not enough; the game must stay in budget for a full play session.

## Requirements

- Profiler overlay: CPU ms per subsystem (game logic, display-list processing, GE submit, audio), heap use, VRAM use, texture cache hit rate.
- Asset streaming instead of loading all assets at boot where the game allows.
- Hot paths to the VFPU: matrix multiply, vertex transform, lighting.
- Frame pacing: lock to 30 or 20 fps based on measured headroom, never uncapped.

## Files (create/modify, in the game fork)

- `port/psp/profiler.c`, changes in `port/psp/gfx_*` and asset loading

## Steps

1. Baseline profile in three heavy scenes.
2. Fix the top costs; repeat until the target frame rate holds.

## Validation

- Target frame rate holds in the three heavy scenes; no heap growth over a 30-minute session.

## Risks

- The chosen game is simply too heavy. Record the measurements and fall back to a lighter game rather than cutting gameplay.

## Rollback

Revert individual optimisations if they break rendering parity.
