---
phase: 6
title: "PPU renderer"
status: completed
effort: 2w
dependsOn: [4]
---

# Phase 06: PPU renderer

## Context

The PPU is reimplemented as a host library that reads VRAM, OAM, palette, and IO registers. Rendering per scanline keeps mid-frame effects correct.

## Requirements

- Modes 0-2 (tiled; BG2/BG3 affine in modes 1-2) and modes 3-5 (bitmap, page flip).
- 128 sprites, regular and affine, 4bpp/8bpp, 1D/2D mapping, OBJ window, semi-transparent sprites, sprite-per-line cycle limit.
- Windows 0/1/OBJ/outside, alpha blending, brightness up/down, mosaic, green swap optional.
- Render one line at HBlank start into an RGB555 buffer; convert to the platform texture at VBlank.
- Optional later: upscaling filters and a GPU path. Not in this phase.

## Files (create)

- `runtime/src/ppu/ppu.cpp`, `ppu/bg_text.cpp`, `ppu/bg_affine.cpp`, `ppu/bg_bitmap.cpp`, `ppu/sprites.cpp`, `ppu/compose.cpp`
- `tests/runtime/ppu_tests.cpp` (golden PNG comparisons)

## Steps

1. Text backgrounds and palette, then sprites, then composition with priority.
2. Affine backgrounds and sprites using the latched reference point registers per line.
3. Windows, blending, mosaic.
4. Golden image tests from tonc demos captured from mGBA.

## Validation

- Pixel-exact match with mGBA screenshots for the tonc demo set (bitmaps, tiles, affine, windows, blending, mosaic).
- A raster-effect demo (HBlank DMA scroll) matches line by line.

## Risks

- Affine reference point latching subtleties. Follow GBATEK and test with tonc `m7_demo`.

## Rollback

Isolated module; revert.
