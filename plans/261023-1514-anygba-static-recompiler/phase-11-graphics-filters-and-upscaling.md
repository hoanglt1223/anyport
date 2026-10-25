---
phase: 11
title: "Graphics filters, colour, and HD upscaling"
status: completed
effort: 1-2w
dependsOn: [10]
---

# Phase 11: Graphics filters, colour, and HD upscaling

## Context

The user wants VisualBoyAdvance-M style video options: interpolation and pixel-art filters, colour depth and correction, and output at 720p, 1080p, 1440p, and 4K. The GBA renders 240x160 in 15-bit BGR555; output is 32-bit. Builds on the on-screen menu from phase 10.

## Requirements

- Filters, selectable in the menu, `--filter`, and the game TOML, switchable while running:
  - nearest, bilinear, sharp-bilinear (integer prescale + bilinear);
  - Scale2x/3x/4x (EPX family), Eagle, 2xSaI, Super Eagle, Super 2xSaI;
  - hq2x/hq3x/hq4x, xBR / xBRZ 2x-6x;
  - LCD grid, GBA LCD ghosting (frame blending), CRT scanlines / simple CRT.
- Colour: raw BGR555 or GBA LCD colour correction (darker, desaturated, matching a GBA screen), optional gamma; output always 32-bit; optional dithering/debanding of gradients.
- Output: window or fullscreen at 720p, 1080p, 1440p, 4K or desktop size; keep the 3:2 aspect; integer-scale option; filters chain (upscaler then screen effect).
- Filters run on the GPU (SDL3 GPU API or shaders) so 4K costs no frame time; a CPU fallback for nearest/bilinear on machines without it.
- Licences: AnyGBA is MIT. xBRZ (GPL-3) and hqx (LGPL) code is not copied; implement from the published algorithm descriptions, and record provenance in THIRD_PARTY.md.

## Files

- `runtime/src/video/` (filter chain, shaders), menu and config integration, `docs/user/VIDEO.md`

## Steps

1. Filter chain and GPU output path with nearest/bilinear/sharp-bilinear and resolution options.
2. Pixel-art scalers and screen effects.
3. Colour correction and dithering.
4. Menu, CLI, TOML; docs and website.

## Validation

- Headless golden images per filter on self-authored test frames (exact or MSE-bounded); every filter renders a 4K frame headless within the frame budget on this PC.
- No window or audio during tests.

## Risks

- GPU API availability on older machines; keep the CPU fallback.

## Decision: CPU scalers, GPU final scale and effects

The pixel-art scalers, colour conversion and ghosting run on the CPU at no more than 6x the GBA
picture (at most 1440x960, all cores); the final scaling to the output size and the screen effects
run on the GPU through SDL_Renderer, and without a GPU the whole chain runs on the CPU. This departs
from "filters run on the GPU" and is kept: per-filter shaders would need SDL_GPU plus a
SPIR-V/DXIL/MSL shader toolchain in every build, while the CPU stage at source scale is well inside
the frame budget and keeps CPU and GPU output identical (golden images). Documented in
`docs/user/VIDEO.md` ("How it runs").

## Implementation status

Completed: every filter in the requirement list, colour correction, gamma, debanding, output
resolutions with 3:2 aspect and integer scaling, chained effects, menu, `--filter`/`--video`, TOML,
`docs/user/VIDEO.md` and the provenance in `THIRD_PARTY.md` (hqx, xBR/xBRZ and the 2xSaI family
written from algorithm descriptions).

- [x] Golden images per filter on self-authored frames pass (`unit-tests`; Windows, CI, Linux 2026-10-25).
- [x] 4K within the frame budget: on the development PC every filter passes `video-timing` on both
  paths. Linux 2026-10-25: the GPU path renders a 4K frame in 2.0-2.2 ms (Mesa llvmpipe, hidden
  window); the CPU-only path measured 20-28 ms for its slowest chain because other jobs kept the
  load average at 15-25 on 16 cores (nearest 2.5 ms, most chains 10-14 ms), so the test was not
  meaningful there.
- [x] No window or audio during tests (hidden window, headless runs).

Leftover (NEEDS-WINDOWS, display): fullscreen and window resizing on a real monitor.
