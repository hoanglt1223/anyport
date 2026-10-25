---
phase: 5
title: "GE renderer on Vulkan"
status: in-progress
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

## Decision (2026-10-24): desktop OpenGL 3.3 first, Vulkan later behind the same seam

The host already had a mature GLES 3 GE backend (`runtime/host/ge_gl.cpp`: surfaces per VRAM region, render-to-texture, stencil-in-alpha, format reinterpretation, internal scaling). Every GL call it makes exists in desktop GL 3.3 core, so porting it took a loader and a shader version line, while a Vulkan backend would mean rewriting that surface manager. No Vulkan SDK is installed on the dev PC either. Vulkan stays the target for Android/MoltenVK and plugs into the same `GeRenderer` seam (`runtime/host/ge_renderer.hpp`).

Status and progress: `plans/reports/fullstack-developer-261023-2356-anypsp-ge-renderer.md` (backend), then `plans/reports/fullstack-developer-261024-0123-anypsp-ge.md` (accuracy: 13/28 exact GE screenshots, Naruto UNH gameplay frames through `anypsp-interp-gpu`).

## Progress (2026-10-25): Vulkan backend, accuracy

Branch `feat/ge-vulkan` in `repos/anypsp` (report: `plans/reports/fullstack-developer-261025-1723-anypsp-ge-vulkan.md`).

- [x] Backend-independent surface manager (`runtime/host/ge_surfaces.cpp`) behind a `GeGpu` device interface; GL refactored onto it with byte-identical GE test pictures and UNH 1 frame hashes.
- [x] Vulkan device (`runtime/gpu/vulkan/`): headless, shared shaders compiled to SPIR-V at build time, pipeline cache on disk, MSAA option, `--renderer vulkan`. Matches GL on all 28 GE screenshot tests and all 113 GE text tests; clean under the validation layer (including synchronization validation).
- [x] GE accuracy: 18/28 screenshot tests exact (was 13), GE text tests 26/113 (was 23; the rest wait on HLE scheduling and functions).
- [x] Vertex morph and skinning verified (pspautotests `vertices/morph` exact; unit tests for skinning, morph, carry, fog); framebuffer readback edge cases covered by unit tests (16-bit packing, only drawn pixels written, transfers after unflushed draws).
- [ ] A Vulkan window/swapchain (the Android host presents `VkGpu::output_image()`); MoltenVK.
- [ ] Bit-exact GE rasterization (Gouraud and depth planes, PSP blend rounding), remaining tests `bezier`, `spline`, `reflection`, `rendertarget`, `texmtx/prims`, `triangle`, `negq`, `normals`, `immediate`.
- [ ] Commercial title at 4x on real hardware comparison; check on Windows (MSVC) and with a real GPU.
