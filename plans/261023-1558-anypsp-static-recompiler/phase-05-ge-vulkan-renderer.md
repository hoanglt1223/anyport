---
phase: 5
title: "GE renderer on Vulkan"
status: pending
effort: 8-12w
dependsOn: [4]
---

# Phase 05: GE renderer on Vulkan

## Context

The PSP GE consumes display lists from RAM. The renderer parses them and draws with Vulkan, with upscaling as a free bonus of running natively.

## Requirements

- Display-list processing (`sceGeListEnQueue`, signals, stall addresses, finish/end), vertex decoding for all formats, morphing and skinning, transform and lighting, texture formats including CLUT and DXT, framebuffer and depth formats.
- Render-to-texture and framebuffer readback detection (games that read framebuffers on the CPU).
- Internal resolution scaling, MSAA, widescreen only via per-game patches.
- Vulkan everywhere; MoltenVK on macOS; Android Vulkan.

## Files (create)

- `runtime/ge/list.*`, `ge/vertex_decoder.*`, `ge/state.*`, `ge/textures.*`, `ge/framebuffers.*`
- `runtime/gpu/vulkan/*`

## Steps

1. Untextured and textured triangles, then lighting and blending.
2. Framebuffer management and render-to-texture.
3. Scaling and performance (pipeline cache).

## Validation

- GE test homebrew renders match PPSSPP output.
- First commercial title renders gameplay correctly at 1x and 4x resolution.

## Risks

- Framebuffer effects (blur, bloom done via CPU or GE copies) are the main source of visual bugs. Track per game.

## Rollback

Module-scoped; revert.
