---
phase: 3
title: "GE renderer and display list"
status: pending
effort: 3w
dependsOn: [2]
---

# Phase 03: GE renderer and display list

## Context

Flash renders a tree of display objects every frame. On the PSP this becomes a walk that emits GE draw calls for precomputed meshes with per-object matrices and color transforms.

## Requirements

- Display list with depths, `PlaceObject2/3`, `RemoveObject2`, clip depths (masks), names, ratios, filters ignored with a warning.
- Timeline playback per MovieClip at the SWF frame rate, independent of the 60 Hz display.
- Matrix stack in 2D; vertex transform on the GE (or VFPU for batches).
- Color transforms: multiply terms through material/vertex color modulation; additive terms through a second additive blend pass only when non-zero.
- Masks via stencil: increment for mask shapes, test for masked content, decrement on exit.
- Blend modes: normal, add, multiply, screen mapped to GE blend; others fall back to normal with a warning.
- Same renderer code with an SDL3/OpenGL backend for the PC target (thin abstraction, not a general engine).

## Files (create)

- `runtime/src/display/display_list.c`, `timeline.c`, `movieclip.c`
- `runtime/src/render/render.h`, `render/ge.c`, `render/gl.c`, `render/mask.c`, `render/color_transform.c`
- `tests/runtime/render_*`

## Steps

1. Display list and timeline without scripts; play an animation-only SWF.
2. Color transforms and masks.
3. Blend modes, then PC backend parity.

## Validation

- Ten animation-only test SWFs play at the correct frame rate on the PSP-3000 and match Ruffle frame captures within the diff threshold.

## Risks

- Draw call count per frame. Batch consecutive meshes sharing texture and blend state.

## Rollback

Module-scoped; revert.
